//
//  APLocationManager.m
//  AstralProjection
//
//  Created by Lvsti on 2010.09.13..
//

#import "APLocationManager.h"
#import "APLocationDataSource.h"
#import "APLocation.h"
#import "APHeading.h"


#if !TARGET_OS_IPHONE
const CLLocationDegrees kCLHeadingFilterNone = -1.0;
#endif


@interface APLocationManager ()
- (void)updateLocationDelegateWithData:(NSArray*)aLocationData;
- (void)updateLocationDelegateWithError:(NSError*)aError;
- (void)updateHeadingDelegateWithHeading:(APHeading*)aHeading;
@end



@implementation APLocationManager

@synthesize location = lastRegisteredLocation;
@synthesize heading = lastRegisteredHeading;

#if !TARGET_OS_IPHONE
@synthesize headingFilter;
#endif


// -----------------------------------------------------------------------------
// APLocationManager::startUpdatingLocation
// -----------------------------------------------------------------------------
- (void)startUpdatingLocation
{
	if ( !locationThread )
	{
		locationThread = [NSThread currentThread];
	}
}


// -----------------------------------------------------------------------------
// APLocationManager::stopUpdatingLocation
// -----------------------------------------------------------------------------
- (void)stopUpdatingLocation
{
	locationThread = nil;
}


// -----------------------------------------------------------------------------
// APLocationManager::startUpdatingHeading
// -----------------------------------------------------------------------------
- (void)startUpdatingHeading
{
	if ( !headingThread )
	{
		headingThread = [NSThread currentThread];
	}
}


// -----------------------------------------------------------------------------
// APLocationManager::stopUpdatingHeading
// -----------------------------------------------------------------------------
- (void)stopUpdatingHeading
{
	headingThread = nil;
}


#pragma mark -
#pragma mark from APLocationDataDelegate:


// -----------------------------------------------------------------------------
// APLocationManager::didUpdateToLocation:fromLocation:
// -----------------------------------------------------------------------------
- (void)didUpdateToLocation:(APLocation*)aNewLocation fromLocation:(APLocation*)aOldLocation
{
	if ( !lastRegisteredLocation || 
		self.distanceFilter == kCLDistanceFilterNone ||
		[aNewLocation distanceFromLocation:lastRegisteredLocation] >= ABS(self.distanceFilter) )
	{
		[lastRegisteredLocation release];
		lastRegisteredLocation = [aNewLocation retain];
		
		if ( locationThread )
		{
			if ( [self.delegate respondsToSelector:@selector(locationManager:didUpdateToLocation:fromLocation:)] )
			{
				if ( locationThread == [NSThread currentThread] )
				{
					[self.delegate locationManager:self
							   didUpdateToLocation:aNewLocation
									  fromLocation:aOldLocation];
				}
				else
				{
					[self performSelector:@selector(updateLocationDelegateWithData:)
								 onThread:locationThread
							   withObject:[NSArray arrayWithObjects:aNewLocation,aOldLocation,nil]
							waitUntilDone:YES];
				}
			}
		}
	}
}


// -----------------------------------------------------------------------------
// APLocationManager::updateLocationDelegateWithData:
// -----------------------------------------------------------------------------
- (void)updateLocationDelegateWithData:(NSArray*)aLocationData
{
	[self.delegate locationManager:self
			   didUpdateToLocation:[aLocationData count]? [aLocationData objectAtIndex:0]: nil
					  fromLocation:([aLocationData count]>1)? [aLocationData objectAtIndex:1]: nil];
}


// -----------------------------------------------------------------------------
// APLocationManager::didFailToUpdateLocationWithError:
// -----------------------------------------------------------------------------
- (void)didFailToUpdateLocationWithError:(NSError*)aError
{
	if ( locationThread )
	{
		if ( [self.delegate respondsToSelector:@selector(locationManager:didFailWithError:)] )
		{
			if ( locationThread == [NSThread currentThread] )
			{
				[self.delegate locationManager:self didFailWithError:aError];
			}
			else
			{
				[self performSelector:@selector(updateLocationDelegateWithError:)
							 onThread:locationThread
						   withObject:aError
						waitUntilDone:NO];
			}
		}
	}
}


// -----------------------------------------------------------------------------
// APLocationManager::updateLocationDelegateWithError:
// -----------------------------------------------------------------------------
- (void)updateLocationDelegateWithError:(NSError*)aError
{
	[self.delegate locationManager:self didFailWithError:aError];
}


#pragma mark -
#pragma mark from APHeadingDataDelegate:


// -----------------------------------------------------------------------------
// APLocationManager::didUpdateToHeading:
// -----------------------------------------------------------------------------
- (void)didUpdateToHeading:(APHeading*)aNewHeading
{
	if ( !lastRegisteredHeading || 
		 self.headingFilter == kCLHeadingFilterNone ||
		 ABS(((CLHeading*)aNewHeading).magneticHeading - lastRegisteredHeading.magneticHeading) >= ABS(self.headingFilter) )
	{
		[lastRegisteredHeading release];
		lastRegisteredHeading = [aNewHeading retain];
		
		if ( headingThread )
		{
			if ( [self.delegate respondsToSelector:@selector(locationManager:didUpdateHeading:)] )
			{
				if ( headingThread == [NSThread currentThread] )
				{
					[self.delegate performSelector:@selector(locationManager:didUpdateHeading:)
										withObject:self
										withObject:aNewHeading];
				}
				else
				{
					[self performSelector:@selector(updateHeadingDelegateWithHeading:)
										  onThread:headingThread
										withObject:aNewHeading
									 waitUntilDone:YES];
				}
			}
		}
	}
}


// -----------------------------------------------------------------------------
// APLocationManager::updateHeadingDelegateWithHeading:
// -----------------------------------------------------------------------------
- (void)updateHeadingDelegateWithHeading:(APHeading*)aHeading
{
	[self.delegate performSelector:@selector(locationManager:didUpdateHeading:)
						withObject:self
						withObject:aHeading];
}


@end
