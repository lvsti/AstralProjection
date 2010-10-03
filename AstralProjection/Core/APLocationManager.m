//
//  APLocationManager.m
//  AstralProjection
//
//  Created by Lvsti on 2010.09.13..
//

#import "APLocationManager.h"
#import "APLocationDataSource.h"


@interface APLocationManager ()
- (void)updateLocationDelegateWithData:(NSArray*)aLocationData;
- (void)updateLocationDelegateWithError:(NSError*)aError;
@end



@implementation APLocationManager

@synthesize location = lastRegisteredLocation;


// -----------------------------------------------------------------------------
// APLocationManager::startUpdatingLocation
// -----------------------------------------------------------------------------
- (void)startUpdatingLocation
{
	callerThread = [NSThread currentThread];
}


// -----------------------------------------------------------------------------
// APLocationManager::stopUpdatingLocation
// -----------------------------------------------------------------------------
- (void)stopUpdatingLocation
{
	callerThread = nil;
	[lastRegisteredLocation release];
	lastRegisteredLocation = nil;
}


#pragma mark -
#pragma mark from APLocationDataDelegate:


// -----------------------------------------------------------------------------
// APLocationManager::didUpdateToLocation:fromLocation:
// -----------------------------------------------------------------------------
- (void)didUpdateToLocation:(CLLocation*)aNewLocation fromLocation:(CLLocation*)aOldLocation
{
	if ( !aOldLocation || [aNewLocation distanceFromLocation:aOldLocation] > self.distanceFilter )
	{
		[lastRegisteredLocation release];
		lastRegisteredLocation = [aNewLocation retain];
		
		if ( callerThread )
		{
			if ( [self.delegate respondsToSelector:@selector(locationManager:didUpdateToLocation:fromLocation:)] )
			{
				if ( callerThread == [NSThread currentThread] )
				{
					[self.delegate locationManager:self
							   didUpdateToLocation:aNewLocation
									  fromLocation:aOldLocation];
				}
				else
				{
					[self performSelector:@selector(updateLocationDelegateWithData:)
								 onThread:callerThread
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
	if ( callerThread )
	{
		if ( [self.delegate respondsToSelector:@selector(locationManager:didFailWithError:)] )
		{
			if ( callerThread == [NSThread currentThread] )
			{
				[self.delegate locationManager:self didFailWithError:aError];
			}
			else
			{
				[self performSelector:@selector(updateLocationDelegateWithError:)
							 onThread:callerThread
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


@end
