//
//  APGPXDataSource.m
//  AstralProjection
//
//  Created by Lkxf on 2010.09.13..
//

#import "APGPXDataSource.h"

#import <CoreLocation/CoreLocation.h>

#import "APGPXParser.h"
#import "APLocationDataDelegate.h"
#import "APLocation.h"


static const CLLocationAccuracy kAPGPXDefaultHorizontalAccuracy = 10.0;
static const CLLocationAccuracy kAPGPXDefaultVerticalAccuracy = 10.0;
static const CLLocationAccuracy kAPGPXInvalidAccuracy = -1.0;

static const NSInteger kThreadExecuting = 0;
static const NSInteger kThreadStopping = 1;
static const NSInteger kThreadStopped = 2;


typedef NS_ENUM(NSUInteger, APGPXInterpolationMethod)
{
	kAPGPXInterpolationMethodNone,
	kAPGPXInterpolationMethodLinear
};


@interface APGPXDataSource ()
{
	NSArray* _waypoints;
	NSArray* _routes;
	NSArray* _tracks;
	
	APGPXDataSet _activeDataSet;
	NSUInteger _activeSubsetIndex;
	
	NSConditionLock* _threadLock;
}

@end


@implementation APGPXDataSource

- (id)initWithContentsOfURL:(NSURL*)aURL
{
    NSParameterAssert(aURL);
    self = [super init];
	if (self)
	{
		_timeScale = 1.0;
		_eventFrequency = 0.0;
		_autorepeat = NO;
		
		_threadLock = [[NSConditionLock alloc] initWithCondition:kThreadStopped];
		
		APGPXParser* gpx = [[APGPXParser alloc] initWithContentsOfURL:aURL];
		
        _waypoints = gpx.waypoints;
        _routes = gpx.routes;
        _tracks = gpx.tracks;
	}
	
	return self;
}


- (void)dealloc
{
	[_threadLock lock];
	if ( [_threadLock condition] == kThreadExecuting )
	{
		[_threadLock unlockWithCondition:kThreadStopping];
	}
	else
	{
		[_threadLock unlock];
	}

	
	[_threadLock lockWhenCondition:kThreadStopped];
	[_threadLock unlock];
}


#pragma mark - new methods:


- (NSUInteger)cardinalityForDataSet:(APGPXDataSet)aDataSet
{
	NSUInteger count = 0;
	
	switch (aDataSet)
	{
		case kAPGPXDataSetWaypoint: count = 1; break;
		case kAPGPXDataSetRoute: count = _routes.count; break;
		case kAPGPXDataSetTrack: count = _tracks.count; break;
	}
	
	return count;
}


- (void)setActiveDataSet:(APGPXDataSet)aDataSet subsetIndex:(NSUInteger)aIndex
{
	_activeDataSet = aDataSet;
	
	if (_activeDataSet == kAPGPXDataSetRoute && aIndex >= _routes.count)
	{
		[NSException raise:NSRangeException
					format:@"Route data set bounds exceeded (count:%lu, accessed:%lu)",(unsigned long)_routes.count,(unsigned long)aIndex];
	}
	else if (_activeDataSet == kAPGPXDataSetTrack && aIndex >= _tracks.count)
	{
		[NSException raise:NSRangeException
					format:@"Track data set bounds exceeded (count:%lu, accessed:%lu)",(unsigned long)_tracks.count,(unsigned long)aIndex];
	}

	_activeSubsetIndex = aIndex;
}


- (void)getStartDate:(NSDate**)aStartDate andStopDate:(NSDate**)aStopDate
{
	NSArray* pointSet = nil;
	
	switch (_activeDataSet)
	{
		case kAPGPXDataSetWaypoint:
		{
			pointSet = _waypoints; 
			break;
		}
			
		case kAPGPXDataSetRoute:
		{
			pointSet = _routes[_activeSubsetIndex];
			break;
		}
			
		case kAPGPXDataSetTrack:
		{
			pointSet = _tracks[_activeSubsetIndex][0];
			break;
		}
	}

	if (pointSet.count > 0)
	{
		if (aStartDate)
		{
			*aStartDate = pointSet.firstObject[kGPXPointTime];
		}
		
		if (aStopDate)
		{
			*aStopDate = pointSet.lastObject[kGPXPointTime];
		}
	}
}


- (BOOL)timestamp:(NSDate*)aDate fallsInSegmentFromPoint:(NSDictionary**)aFromPoint
    toPoint:(NSDictionary**)aToPoint inPointSet:(NSArray*)aPoints
{
	BOOL segmentFound = NO;
	
	for (int i = 0; i < aPoints.count; ++i)
	{
		*aFromPoint = *aToPoint;
		*aToPoint = aPoints[i];
		
		if ([aDate timeIntervalSinceDate:(*aToPoint)[kGPXPointTime]] < 0)
		{
			segmentFound = YES;
			break;
		}				
	}
	
	return segmentFound;
}


- (APLocation*)locationForDate:(NSDate*)aDate withInterpolation:(APGPXInterpolationMethod)aMethod
{
	NSDictionary* fromPoint = nil;
	NSDictionary* toPoint = nil;
	
	switch (_activeDataSet)
	{
		case kAPGPXDataSetWaypoint:
		{
			if (![self timestamp:aDate fallsInSegmentFromPoint:&fromPoint
                         toPoint:&toPoint inPointSet:_waypoints] ||
				!fromPoint)
			{
				fromPoint = toPoint;
			}
			break;
		}

		case kAPGPXDataSetRoute:
		{
			if (![self timestamp:aDate fallsInSegmentFromPoint:&fromPoint
                         toPoint:&toPoint inPointSet:_routes[_activeSubsetIndex]] ||
				!fromPoint )
			{
				fromPoint = toPoint;
			}
			break;
		}
		
		case kAPGPXDataSetTrack:
		{
			NSArray* segments = _tracks[_activeSubsetIndex];
			for (int s = 0; s < segments.count; ++s)
			{
				NSArray* points = segments[s];
				
				if (![self timestamp:aDate fallsInSegmentFromPoint:&fromPoint toPoint:&toPoint inPointSet:points] ||
					!fromPoint)
				{
					fromPoint = toPoint;
				}
			}
			
			break;
		}
	}
	
	CLLocationDegrees latitude = 0.0;
	CLLocationDegrees longitude = 0.0;
	CLLocationDistance altitude = 0.0;
	CLLocationAccuracy vAccuracy = kAPGPXInvalidAccuracy;
	CLLocationSpeed speed = -1.0;
	CLLocationDegrees course = -1.0;
	
	switch (aMethod)
	{
		case kAPGPXInterpolationMethodNone:
		{
			latitude = [fromPoint[kGPXPointLatitude] doubleValue];
			longitude = [fromPoint[kGPXPointLongitude] doubleValue];
			
			if (fromPoint[kGPXPointAltitude])
			{
				altitude = [fromPoint[kGPXPointAltitude] doubleValue];
				vAccuracy = kAPGPXDefaultVerticalAccuracy;
			}

			break;
		}
		
		case kAPGPXInterpolationMethodLinear:
		{
			NSTimeInterval timeDelta = [toPoint[kGPXPointTime] timeIntervalSinceDate:fromPoint[kGPXPointTime]];
			double progress = 0.0;
			
			if (timeDelta > 0.0)
			{
				progress = [aDate timeIntervalSinceDate:fromPoint[kGPXPointTime]] / timeDelta;
			}
			
			CLLocationDegrees fromValue;
			fromValue = [fromPoint[kGPXPointLatitude] doubleValue];
			latitude = fromValue + progress * ([toPoint[kGPXPointLatitude] doubleValue] - fromValue);
			fromValue = [fromPoint[kGPXPointLongitude] doubleValue];
			longitude =  fromValue + progress * ([toPoint[kGPXPointLongitude] doubleValue] - fromValue);
			
			if ([fromPoint objectForKey:kGPXPointAltitude])
			{
				CLLocationDistance fromAlt = [fromPoint[kGPXPointAltitude] doubleValue];
				altitude = fromAlt + progress * ([toPoint[kGPXPointAltitude] doubleValue] - fromAlt);

				vAccuracy = kAPGPXDefaultVerticalAccuracy;
			}
			
			break;
		}
	}
	
	if (toPoint != fromPoint)
	{
		CLLocation* fromLocation = [[CLLocation alloc] initWithLatitude:[fromPoint[kGPXPointLatitude] doubleValue]
															  longitude:[fromPoint[kGPXPointLongitude] doubleValue]];
		CLLocation* toLocation = [[CLLocation alloc] initWithLatitude:[toPoint[kGPXPointLatitude] doubleValue]
															longitude:[toPoint[kGPXPointLongitude] doubleValue]];

		// calculate speed if applicable
		NSTimeInterval timeDelta = [toPoint[kGPXPointTime] timeIntervalSinceDate:fromPoint[kGPXPointTime]];
		
		if (timeDelta > 0.0)
		{
			speed = [toLocation distanceFromLocation:fromLocation] / timeDelta;
		}

		// calculate course
		// NOTE: This calculation is NOT ACCURATE because it works on a 2D flat projection of the globe.
		//       Expect it to fail close to the poles and when crossing -180 W / 180 E. You have been warned.
		
		// alpha is zero towards east and grows counterclockwise, radians
		double alpha = atan2(toLocation.coordinate.latitude - fromLocation.coordinate.latitude,
							 toLocation.coordinate.longitude - fromLocation.coordinate.longitude);
		
		// course is zero towards the north and grows clockwise, degrees
		course = -(alpha*180.0/M_PI - 90.0);
		if (course < 0)
		{
			course += 360.0;
		}
	}

	APLocation* location = [[APLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude,longitude)
														 altitude:altitude
											   horizontalAccuracy:kAPGPXDefaultHorizontalAccuracy
												 verticalAccuracy:vAccuracy
														   course:course
															speed:speed
														timestamp:aDate];
	
    return location;
}


- (APLocation*)locationWithPointAtIndex:(NSUInteger)aIndex
{
	NSDictionary* point = nil;
	NSDictionary* toPoint = nil;
	
	switch (_activeDataSet)
	{
		case kAPGPXDataSetWaypoint:
		{
			if (aIndex >= _waypoints.count)
			{
				break;
			}
			
			point = _waypoints[aIndex];
			if (aIndex + 1 < _waypoints.count)
			{
				toPoint = _waypoints[aIndex+1];
			}
			break;
		}
			
		case kAPGPXDataSetRoute:
		{
			if (aIndex >= [_routes[_activeSubsetIndex] count] )
			{
				break;
			}

			point = _routes[_activeSubsetIndex][aIndex];
			if ( aIndex + 1 < [_routes[_activeSubsetIndex] count] )
			{
				toPoint = _routes[_activeSubsetIndex][aIndex+1];
			}
			
			break;
		}
			
		case kAPGPXDataSetTrack:
		{
			NSArray* segments = _tracks[_activeSubsetIndex];
			int numPoints = 0;
			for (int s = 0; s < segments.count; ++s)
			{
				NSArray* points = segments[s];
				
				if (aIndex < numPoints + points.count)
				{
					point = points[aIndex-numPoints];
					if (aIndex-numPoints+1 < points.count)
					{
						toPoint = points[aIndex-numPoints+1];
					}
					break;
				}

				numPoints += points.count;
			}
			
			break;
		}
	}
	
	if (!point)
	{
		return nil;
	}
	
	CLLocationDegrees latitude = [point[kGPXPointLatitude] doubleValue];
	CLLocationDegrees longitude = [point[kGPXPointLongitude] doubleValue];
	CLLocationDistance altitude = 0.0;
	CLLocationAccuracy vAccuracy = kAPGPXInvalidAccuracy;
	CLLocationSpeed speed = -1.0;
	CLLocationDegrees course = -1.0;
	
	if (point[kGPXPointAltitude])
	{
		altitude = [point[kGPXPointAltitude] doubleValue];
		vAccuracy = kAPGPXDefaultVerticalAccuracy;
	}
	
	CLLocation* tempLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude,longitude)
															 altitude:altitude
												   horizontalAccuracy:kAPGPXDefaultHorizontalAccuracy
													 verticalAccuracy:vAccuracy
															timestamp:point[kGPXPointTime]];
	
	if (toPoint)
	{
		CLLocation* toLocation = [[CLLocation alloc] initWithLatitude:[[toPoint objectForKey:kGPXPointLatitude] doubleValue]
															longitude:[[toPoint objectForKey:kGPXPointLongitude] doubleValue]];
		
		// calculate speed if applicable
		NSTimeInterval timeDelta = [toPoint[kGPXPointTime] timeIntervalSinceDate:point[kGPXPointTime]];
		
		if (timeDelta > 0.0)
		{
			speed = [toLocation distanceFromLocation:tempLocation] / timeDelta;
		}
		
		// calculate course
		// NOTE: This calculation is NOT ACCURATE because it works on a 2D flat projection of the globe.
		//       Expect it to fail close to the poles and when crossing -180 W / 180 E. You have been warned.
		
		// alpha is zero towards east and grows counterclockwise, radians
		double alpha = atan2(toLocation.coordinate.latitude - tempLocation.coordinate.latitude,
							 toLocation.coordinate.longitude - tempLocation.coordinate.longitude);
		
		// course is zero towards the north and grows clockwise, degrees
		course = -(alpha*180.0/M_PI - 90.0);
		if ( course < 0 )
		{
			course += 360.0;
		}
	}
	
	APLocation* location = [[APLocation alloc] initWithCoordinate:tempLocation.coordinate
														 altitude:tempLocation.altitude
											   horizontalAccuracy:tempLocation.horizontalAccuracy
												 verticalAccuracy:tempLocation.verticalAccuracy
														   course:course
															speed:speed
														timestamp:tempLocation.timestamp];
	
    return location;
}


- (void)eventGeneratorLoop
{
    @autoreleasepool {
	
	[_threadLock lockWhenCondition:kThreadExecuting];
	[_threadLock unlock];
	
	NSDate* virtualStart = nil;
	NSDate* virtualStop = nil;
	[self getStartDate:&virtualStart andStopDate:&virtualStop];

	APLocation* oldLocation = nil;
	APLocation* newLocation = nil;
	BOOL endPointPassed = NO;
	NSUInteger pointIndex = 0;
	double safeTimeScale = _timeScale? _timeScale: 1.0;
	NSTimeInterval safeEventFrequency = (_eventFrequency >= 0.0)? _eventFrequency: 0.0;
	BOOL safeAutorepeat = _autorepeat;
	
	NSDate* start = [NSDate date];
	
	[_threadLock lock];
	while (_threadLock.condition != kThreadStopping)
	{
		[_threadLock unlock];
		
        @autoreleasepool {
		
		if (safeEventFrequency > 0)
		{
			// events are generated at a given frequency
			// to get the current location, we must interpolate between the discrete data points
            NSDate* now = [NSDate date];
			NSTimeInterval elapsed = [now timeIntervalSinceDate:start];
			NSTimeInterval virtualElapsed = elapsed * safeTimeScale;
			NSDate* virtualNow = [NSDate dateWithTimeInterval:virtualElapsed sinceDate:virtualStart];

			if ([virtualNow timeIntervalSinceDate:virtualStop] > 0)
			{
				// end of recorded interval reached
				// we still allow one more iteration to ensure the endpoint is sent to the delegate
				if (endPointPassed)
				{
					// safety iteration is done
					if (!safeAutorepeat)
					{
						// exit the loop
                        @autoreleasepool {
                            [_locationDataDelegate locationDataSource:self
                                     didFailToUpdateLocationWithError:[NSError errorWithDomain:kCLErrorDomain
                                                                                          code:kCLErrorLocationUnknown
                                                                                      userInfo:nil]];
                        }
						
						[_threadLock lock];
						[_threadLock unlockWithCondition:kThreadStopping];
					}
					else
					{
						// rewind and restart
						endPointPassed = NO;
                        start = [NSDate date];
					}

					[_threadLock lock];
					continue;
				}
				else
				{
					endPointPassed = YES;
				}
			}
			
			oldLocation = newLocation;
			APLocation* intLocation = [self locationForDate:virtualNow
										  withInterpolation:kAPGPXInterpolationMethodLinear];
			newLocation = [[APLocation alloc] initWithLocation:intLocation
													 timestamp:now];
//			NSLog(@"%@",newLocation);
			
			// notify the location manager
			[_locationDataDelegate locationDataSource:self
								 didUpdateToLocation:newLocation
										fromLocation:oldLocation];

			// sleep until next firing time
			NSDate* scheduleTime = [[NSDate alloc] initWithTimeInterval:safeEventFrequency sinceDate:now];
			if (![_threadLock lockWhenCondition:kThreadStopping beforeDate:scheduleTime])
			{
				[_threadLock lock];
			}
		}
		else
		{
			// event frequency follows actual data set events
			oldLocation = newLocation;
			newLocation = [self locationWithPointAtIndex:pointIndex];
			
//			NSLog(@"%@",newLocation);
			if (!newLocation)
			{
				// run out of points
				if (!safeAutorepeat)
				{
					// exit the loop
					[_locationDataDelegate locationDataSource:self
							didFailToUpdateLocationWithError:[NSError errorWithDomain:kCLErrorDomain
																				 code:kCLErrorLocationUnknown
																			 userInfo:nil]];
					 
					
					[_threadLock lock];
					[_threadLock unlockWithCondition:kThreadStopping];
				}
				else
				{
					// rewind and restart
					oldLocation = nil;
					pointIndex = 0;
				}

				[_threadLock lock];
				continue;
			}

			NSDate* virtualTimestamp = newLocation.timestamp;
			NSTimeInterval virtualElapsed = [virtualTimestamp timeIntervalSinceDate:virtualStart];
			NSTimeInterval elapsed = virtualElapsed / safeTimeScale;
			NSDate* scheduleTime = [[NSDate alloc] initWithTimeInterval:elapsed sinceDate:start];
			
			if ([scheduleTime timeIntervalSinceDate:[NSDate date]] > 0)
			{
				if (![_threadLock lockWhenCondition:kThreadStopping beforeDate:scheduleTime])
				{
					[_threadLock lock];
				}
			}
			else
			{
				[_threadLock lock];
			}

			if (_threadLock.condition != kThreadStopping)
			{
				[_threadLock unlock];
				
				// wrap the delegate call into another autorelease pool because nestedPool can already be released here
				APLocation* tmpLocation = newLocation;
				newLocation = [[APLocation alloc] initWithLocation:tmpLocation
														 timestamp:[NSDate date]];

                @autoreleasepool {
                    [_locationDataDelegate locationDataSource:self
                                          didUpdateToLocation:newLocation
                                                 fromLocation:oldLocation];
                }
				
				[_threadLock lock];
			}
			++pointIndex;
		}
        }
	}
	
	[_threadLock unlock];
	
	// put cleanup here
	[_threadLock lock];
	[_threadLock unlockWithCondition:kThreadStopped];
    }
}


#pragma mark - from APLocationDataSource:


- (void)startGeneratingLocationEvents
{
	[_threadLock lock];
	if (_threadLock.condition == kThreadStopped)
	{
		[NSThread detachNewThreadSelector:@selector(eventGeneratorLoop)
								 toTarget:self
							   withObject:nil];
		
		[_threadLock unlockWithCondition:kThreadExecuting];
	}
	else
	{
		[_threadLock unlock];
	}
}


- (void)stopGeneratingLocationEvents
{
	[_threadLock lock];
	if (_threadLock.condition == kThreadExecuting)
	{
		[_threadLock unlockWithCondition:kThreadStopping];
	}
	else
	{
		[_threadLock unlock];
	}
}


@end
