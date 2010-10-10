//
//  APGPXDataSource.m
//  AstralProjection
//
//  Created by Lvsti on 2010.09.13..
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


typedef enum
{
	kAPGPXInterpolationMethodNone,
	kAPGPXInterpolationMethodLinear
} APGPXInterpolationMethod;



@interface APGPXDataSource ()

- (void)getStartDate:(NSDate**)aStartDate andStopDate:(NSDate**)aStopDate;
- (BOOL)timestamp:(NSDate*)aDate fallsInSegmentFromPoint:(NSDictionary**)aFromPoint
		  toPoint:(NSDictionary**)aToPoint inPointSet:(NSArray*)aPoints;
- (APLocation*)locationForDate:(NSDate*)aDate withInterpolation:(APGPXInterpolationMethod)aMethod;
- (APLocation*)locationWithPointAtIndex:(NSUInteger)aIndex;
- (void)eventGeneratorLoop;

@end



@implementation APGPXDataSource

@synthesize timeScale;
@synthesize eventFrequency;
@synthesize locationDataDelegate;


// -----------------------------------------------------------------------------
// APGPXDataSource::initWithURL:
// -----------------------------------------------------------------------------
- (id)initWithURL:(NSURL*)aUrl
{
	if ( (self = [super init]) )
	{
		timeScale = 1.0;
		eventFrequency = 0.0;
		
		threadLock = [[NSConditionLock alloc] initWithCondition:kThreadStopped];
		
		APGPXParser* gpx = [[APGPXParser alloc] initWithURL:aUrl];
		
		waypoints = [gpx.waypoints retain];
		routes = [gpx.routes retain];
		tracks = [gpx.tracks retain];
		
		[gpx release];
	}
	
	return self;
}


// -----------------------------------------------------------------------------
// APGPXDataSource::dealloc
// -----------------------------------------------------------------------------
- (void)dealloc
{
	[threadLock lock];
	if ( [threadLock condition] == kThreadExecuting )
	{
		[threadLock unlockWithCondition:kThreadStopping];
	}
	else
	{
		[threadLock unlock];
	}

	
	[threadLock lockWhenCondition:kThreadStopped];
	[threadLock unlock];
	
	[threadLock release];
	
	[waypoints release];
	[routes release];
	[tracks release];
	
	[super dealloc];
}


#pragma mark -
#pragma mark new methods:


// -----------------------------------------------------------------------------
// APGPXDataSource::cardinalityForDataSet:
// -----------------------------------------------------------------------------
- (NSUInteger)cardinalityForDataSet:(APGPXDataSet)aDataSet
{
	NSUInteger count = 0;
	
	switch ( aDataSet )
	{
		case kAPGPXDataSetWaypoint: count = 1; break;
		case kAPGPXDataSetRoute: count = [routes count]; break;
		case kAPGPXDataSetTrack: count = [tracks count]; break;
	}
	
	return count;
}


// -----------------------------------------------------------------------------
// APGPXDataSource::setActiveDataSet:subsetIndex:
// -----------------------------------------------------------------------------
- (void)setActiveDataSet:(APGPXDataSet)aDataSet subsetIndex:(NSUInteger)aIndex
{
	activeDataSet = aDataSet;
	
	if ( activeDataSet == kAPGPXDataSetRoute && aIndex >= [routes count] )
	{
		[NSException raise:NSRangeException
					format:@"Route data set bounds exceeded (count:%d, accessed:%d)",[routes count],aIndex];
	}
	else if ( activeDataSet == kAPGPXDataSetTrack && aIndex >= [tracks count] )
	{
		[NSException raise:NSRangeException
					format:@"Track data set bounds exceeded (count:%d, accessed:%d)",[tracks count],aIndex];
	}

	activeSubsetIndex = aIndex;
}


// -----------------------------------------------------------------------------
// APGPXDataSource::getStartDate:andStopDate:
// -----------------------------------------------------------------------------
- (void)getStartDate:(NSDate**)aStartDate andStopDate:(NSDate**)aStopDate
{
	NSArray* pointSet = nil;
	
	switch ( activeDataSet )
	{
		case kAPGPXDataSetWaypoint:
		{
			pointSet = waypoints; 
			break;
		}
			
		case kAPGPXDataSetRoute:
		{
			pointSet = [routes objectAtIndex:activeSubsetIndex];
			break;
		}
			
		case kAPGPXDataSetTrack:
		{
			pointSet = [[tracks objectAtIndex:activeSubsetIndex] objectAtIndex:0];
			break;
		}
	}

	if ( [pointSet count] )
	{
		if ( aStartDate )
		{
			*aStartDate = [[pointSet objectAtIndex:0] objectForKey:kGPXPointTime];
		}
		
		if ( aStopDate )
		{
			*aStopDate = [[pointSet lastObject] objectForKey:kGPXPointTime];
		}
	}
}


// -----------------------------------------------------------------------------
// APGPXDataSource::timestamp:fallsInSegmentFromPoint:toPoint:inPointSet:
// -----------------------------------------------------------------------------
- (BOOL)timestamp:(NSDate*)aDate fallsInSegmentFromPoint:(NSDictionary**)aFromPoint
		  toPoint:(NSDictionary**)aToPoint inPointSet:(NSArray*)aPoints
{
	BOOL segmentFound = NO;
	
	for ( int i = 0; i < [aPoints count]; ++i )
	{
		*aFromPoint = *aToPoint;
		*aToPoint = [aPoints objectAtIndex:i];
		
		if ( [aDate timeIntervalSinceDate:[*aToPoint objectForKey:kGPXPointTime]] < 0 )
		{
			segmentFound = YES;
			break;
		}				
	}
	
	return segmentFound;
}


// -----------------------------------------------------------------------------
// APGPXDataSource::locationForDate:withInterpolation:
// -----------------------------------------------------------------------------
- (APLocation*)locationForDate:(NSDate*)aDate withInterpolation:(APGPXInterpolationMethod)aMethod
{
	NSDictionary* fromPoint = nil;
	NSDictionary* toPoint = nil;
	
	switch ( activeDataSet )
	{
		case kAPGPXDataSetWaypoint:
		{
			if ( ![self timestamp:aDate fallsInSegmentFromPoint:&fromPoint toPoint:&toPoint inPointSet:waypoints] ||
				 !fromPoint )
			{
				fromPoint = toPoint;
			}
			break;
		}

		case kAPGPXDataSetRoute:
		{
			if ( ![self timestamp:aDate fallsInSegmentFromPoint:&fromPoint toPoint:&toPoint
					   inPointSet:[routes objectAtIndex:activeSubsetIndex]] ||
				!fromPoint )
			{
				fromPoint = toPoint;
			}
			break;
		}
		
		case kAPGPXDataSetTrack:
		{
			NSArray* segments = [tracks objectAtIndex:activeSubsetIndex];
			for ( int s = 0; s < [segments count]; ++s )
			{
				NSArray* points = [segments objectAtIndex:s];
				
				if ( ![self timestamp:aDate fallsInSegmentFromPoint:&fromPoint toPoint:&toPoint inPointSet:points] ||
					!fromPoint )
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
	
	switch ( aMethod )
	{
		case kAPGPXInterpolationMethodNone:
		{
			latitude = [[fromPoint objectForKey:kGPXPointLatitude] doubleValue];
			longitude = [[fromPoint objectForKey:kGPXPointLongitude] doubleValue];
			
			if ( [fromPoint objectForKey:kGPXPointAltitude] )
			{
				altitude = [[fromPoint objectForKey:kGPXPointAltitude] doubleValue];
				vAccuracy = kAPGPXDefaultVerticalAccuracy;
			}

			break;
		}
		
		case kAPGPXInterpolationMethodLinear:
		{
			NSTimeInterval timeDelta = [[toPoint objectForKey:kGPXPointTime] timeIntervalSinceDate:[fromPoint objectForKey:kGPXPointTime]];
			double progress = 0.0;
			
			if ( timeDelta > 0.0 )
			{
				progress = [aDate timeIntervalSinceDate:[fromPoint objectForKey:kGPXPointTime]] / timeDelta;
			}
			
			CLLocationDegrees fromValue;
			fromValue = [[fromPoint objectForKey:kGPXPointLatitude] doubleValue];
			latitude = fromValue + progress * ([[toPoint objectForKey:kGPXPointLatitude] doubleValue] - fromValue);
			fromValue = [[fromPoint objectForKey:kGPXPointLongitude] doubleValue];
			longitude =  fromValue + progress * ([[toPoint objectForKey:kGPXPointLongitude] doubleValue] - fromValue);
			
			if ( [fromPoint objectForKey:kGPXPointAltitude] )
			{
				CLLocationDistance fromAlt = [[fromPoint objectForKey:kGPXPointAltitude] doubleValue];
				altitude = fromAlt + progress * ([[toPoint objectForKey:kGPXPointAltitude] doubleValue] - fromAlt);

				vAccuracy = kAPGPXDefaultVerticalAccuracy;
			}
			
			break;
		}
	}
	
	APLocation* location = [[APLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude,longitude)
														 altitude:altitude
											   horizontalAccuracy:kAPGPXDefaultHorizontalAccuracy
												 verticalAccuracy:vAccuracy
														timestamp:aDate];

	if ( toPoint != fromPoint )
	{
		APLocation* fromLocation = [[APLocation alloc] initWithLatitude:[[fromPoint objectForKey:kGPXPointLatitude] doubleValue]
															  longitude:[[fromPoint objectForKey:kGPXPointLongitude] doubleValue]];
		APLocation* toLocation = [[APLocation alloc] initWithLatitude:[[toPoint objectForKey:kGPXPointLatitude] doubleValue]
															longitude:[[toPoint objectForKey:kGPXPointLongitude] doubleValue]];

		// calculate speed if applicable
		NSTimeInterval timeDelta = [[toPoint objectForKey:kGPXPointTime] timeIntervalSinceDate:[fromPoint objectForKey:kGPXPointTime]];
		
		if ( timeDelta > 0.0 )
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
		if ( course < 0 )
		{
			course += 360.0;
		}

		[toLocation release];
		[fromLocation release];
	}

	location.speed = speed;
	location.course = course;

	return [location autorelease];
}


// -----------------------------------------------------------------------------
// APGPXDataSource::locationWithPointAtIndex:
// -----------------------------------------------------------------------------
- (APLocation*)locationWithPointAtIndex:(NSUInteger)aIndex
{
	NSDictionary* point = nil;
	NSDictionary* toPoint = nil;
	
	switch ( activeDataSet )
	{
		case kAPGPXDataSetWaypoint:
		{
			if ( aIndex >= [waypoints count] )
			{
				break;
			}
			
			point = [waypoints objectAtIndex:aIndex];
			if ( aIndex + 1 < [waypoints count] )
			{
				toPoint = [waypoints objectAtIndex:aIndex+1];
			}
			break;
		}
			
		case kAPGPXDataSetRoute:
		{
			if ( aIndex >= [[routes objectAtIndex:activeSubsetIndex] count] )
			{
				break;
			}

			point = [[routes objectAtIndex:activeSubsetIndex] objectAtIndex:aIndex];
			if ( aIndex + 1 < [[routes objectAtIndex:activeSubsetIndex] count] )
			{
				toPoint = [[routes objectAtIndex:activeSubsetIndex] objectAtIndex:aIndex+1];
			}
			
			break;
		}
			
		case kAPGPXDataSetTrack:
		{
			NSArray* segments = [tracks objectAtIndex:activeSubsetIndex];
			int numPoints = 0;
			for ( int s = 0; s < [segments count]; ++s )
			{
				NSArray* points = [segments objectAtIndex:s];
				
				if ( aIndex < numPoints + [points count] )
				{
					point = [points objectAtIndex:aIndex-numPoints];
					if ( aIndex-numPoints+1 < [points count] )
					{
						toPoint = [points objectAtIndex:aIndex-numPoints+1];
					}
					break;
				}

				numPoints += [points count];
			}
			
			break;
		}
	}
	
	if ( !point )
	{
		return nil;
	}
	
	CLLocationDegrees latitude = [[point objectForKey:kGPXPointLatitude] doubleValue];
	CLLocationDegrees longitude = [[point objectForKey:kGPXPointLongitude] doubleValue];
	CLLocationDistance altitude = 0.0;
	CLLocationAccuracy vAccuracy = kAPGPXInvalidAccuracy;
	CLLocationSpeed speed = -1.0;
	CLLocationDegrees course = -1.0;
	
	if ( [point objectForKey:kGPXPointAltitude] )
	{
		altitude = [[point objectForKey:kGPXPointAltitude] doubleValue];
		vAccuracy = kAPGPXDefaultVerticalAccuracy;
	}
	
	APLocation* location = [[APLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude,longitude)
														 altitude:altitude
											   horizontalAccuracy:kAPGPXDefaultHorizontalAccuracy
												 verticalAccuracy:vAccuracy
														timestamp:[point objectForKey:kGPXPointTime]];
	
	if ( toPoint )
	{
		APLocation* toLocation = [[APLocation alloc] initWithLatitude:[[toPoint objectForKey:kGPXPointLatitude] doubleValue]
															longitude:[[toPoint objectForKey:kGPXPointLongitude] doubleValue]];
		
		// calculate speed if applicable
		NSTimeInterval timeDelta = [[toPoint objectForKey:kGPXPointTime] timeIntervalSinceDate:[point objectForKey:kGPXPointTime]];
		
		if ( timeDelta > 0.0 )
		{
			speed = [toLocation distanceFromLocation:location] / timeDelta;
		}
		
		// calculate course
		// NOTE: This calculation is NOT ACCURATE because it works on a 2D flat projection of the globe.
		//       Expect it to fail close to the poles and when crossing -180 W / 180 E. You have been warned.
		
		// alpha is zero towards east and grows counterclockwise, radians
		double alpha = atan2(toLocation.coordinate.latitude - location.coordinate.latitude,
							 toLocation.coordinate.longitude - location.coordinate.longitude);
		
		// course is zero towards the north and grows clockwise, degrees
		course = -(alpha*180.0/M_PI - 90.0);
		if ( course < 0 )
		{
			course += 360.0;
		}
		
		[toLocation release];
	}
	
	location.speed = speed;
	location.course = course;
	
	return [location autorelease];
}



// -----------------------------------------------------------------------------
// APGPXDataSource::eventGeneratorLoop
// -----------------------------------------------------------------------------
- (void)eventGeneratorLoop
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	[threadLock lockWhenCondition:kThreadExecuting];
	[threadLock unlock];
	
	NSDate* virtualStart = nil;
	NSDate* virtualStop = nil;
	[self getStartDate:&virtualStart andStopDate:&virtualStop];

	APLocation* oldLocation = nil;
	APLocation* newLocation = nil;
	BOOL endPointPassed = NO;
	NSUInteger pointIndex = 0;
	double safeTimeScale = timeScale? timeScale: 1.0;
	NSTimeInterval safeEventFrequency = (eventFrequency >= 0.0)? eventFrequency: 0.0;
	
	NSDate* start = [NSDate date];
	
	[threadLock lock];
	while ( [threadLock condition] != kThreadStopping )
	{
		[threadLock unlock];
		
		if ( safeEventFrequency > 0 )
		{
			// events are generated at a given frequency
			// to get the current location, we must interpolate between the discrete data points
			NSDate* now = [NSDate date];
			NSTimeInterval elapsed = [now timeIntervalSinceDate:start];
			NSTimeInterval virtualElapsed = elapsed * safeTimeScale;
			NSDate* virtualNow = [NSDate dateWithTimeInterval:virtualElapsed sinceDate:virtualStart];

			if ( [virtualNow timeIntervalSinceDate:virtualStop] > 0 )
			{
				// end of recorded interval reached
				// we still allow one more iteration to ensure the endpoint is sent to the delegate
				if ( endPointPassed )
				{
					// safety iteration is done, exit the loop
					[locationDataDelegate didFailToUpdateLocationWithError:
					 [NSError errorWithDomain:kCLErrorDomain
										 code:kCLErrorLocationUnknown
									 userInfo:nil]];
					
					[threadLock lock];
					[threadLock unlockWithCondition:kThreadStopping];
					[threadLock lock];
					continue;
				}
							
				endPointPassed = YES;
			}
			
			oldLocation = newLocation;
			newLocation = [self locationForDate:virtualNow 
							  withInterpolation:kAPGPXInterpolationMethodLinear];
			NSLog(@"%@",newLocation);
			
			// notify the location manager
			[locationDataDelegate didUpdateToLocation:newLocation fromLocation:oldLocation];

			// sleep until next firing time
			if ( ![threadLock lockWhenCondition:kThreadStopping
										   beforeDate:[NSDate dateWithTimeInterval:safeEventFrequency sinceDate:now]] )
			{
				[threadLock lock];
			}
		}
		else
		{
			// event frequency follows actual data set events
			oldLocation = newLocation;
			newLocation = [self locationWithPointAtIndex:pointIndex];
			
			NSLog(@"%@",newLocation);
			if ( !newLocation )
			{
				[locationDataDelegate didFailToUpdateLocationWithError:
				 [NSError errorWithDomain:kCLErrorDomain
									 code:kCLErrorLocationUnknown
								 userInfo:nil]];
				
				[threadLock lock];
				[threadLock unlockWithCondition:kThreadStopping];
				[threadLock lock];
				continue;
			}

			NSDate* virtualTimestamp = newLocation.timestamp;
			NSTimeInterval virtualElapsed = [virtualTimestamp timeIntervalSinceDate:virtualStart];
			NSTimeInterval elapsed = virtualElapsed / safeTimeScale;
			NSDate* scheduleTime = [NSDate dateWithTimeInterval:elapsed sinceDate:start];
			
			if ( [scheduleTime timeIntervalSinceDate:[NSDate date]] > 0 )
			{
				if ( ![threadLock lockWhenCondition:kThreadStopping beforeDate:scheduleTime] )
				{
					[threadLock lock];
				}
			}
			else
			{
				[threadLock lock];
			}

			if ( [threadLock condition] != kThreadStopping )
			{
				[threadLock unlock];
				
				[locationDataDelegate didUpdateToLocation:newLocation fromLocation:oldLocation];
				
				[threadLock lock];
			}
			++pointIndex;
		}
	}
	
	[threadLock unlock];
	
	// put cleanup here
	
	[threadLock lock];
	[threadLock unlockWithCondition:kThreadStopped];
	
	[pool release];
}


#pragma mark -
#pragma mark from APLocationDataSource:


// -----------------------------------------------------------------------------
// APGPXDataSource::startGeneratingLocationEvents
// -----------------------------------------------------------------------------
- (void)startGeneratingLocationEvents
{
	[threadLock lock];
	if ( [threadLock condition] == kThreadStopped )
	{
		[NSThread detachNewThreadSelector:@selector(eventGeneratorLoop)
								 toTarget:self
							   withObject:nil];
		
		[threadLock unlockWithCondition:kThreadExecuting];
	}
	else
	{
		[threadLock unlock];
	}
}


// -----------------------------------------------------------------------------
// APGPXDataSource::stopGeneratingLocationEvents
// -----------------------------------------------------------------------------
- (void)stopGeneratingLocationEvents
{
	[threadLock lock];
	if ( [threadLock condition] == kThreadExecuting )
	{
		[threadLock unlockWithCondition:kThreadStopping];
	}
	else
	{
		[threadLock unlock];
	}
}



@end
