//
//  APLocation.m
//  AstralProjection
//
//  Created by Lkxf on 2011.02.03..
//

#import "APLocation.h"

#if !TARGET_OS_IPHONE && __MAC_OS_X_VERSION_MIN_REQUIRED <= __MAC_10_6

CLLocationCoordinate2D CLLocationCoordinate2DMake(CLLocationDegrees aLatitude,
												  CLLocationDegrees aLongitude)
{
	CLLocationCoordinate2D coord;
	coord.latitude = aLatitude;
	coord.longitude = aLongitude;
	return coord;
}

#endif


@implementation CLLocation (AstralProjection)

- (id)initWithLocation:(CLLocation*)aLocation
			 timestamp:(NSDate*)aTimestamp
{
#if TARGET_OS_IPHONE || __MAC_OS_X_VERSION_MIN_REQUIRED > __MAC_10_6
	return [self initWithCoordinate:aLocation.coordinate
						   altitude:aLocation.altitude
				 horizontalAccuracy:aLocation.horizontalAccuracy
				   verticalAccuracy:aLocation.verticalAccuracy
							 course:aLocation.course
							  speed:aLocation.speed
						  timestamp:aTimestamp];
#else
	return [self initWithCoordinate:aLocation.coordinate
						   altitude:aLocation.altitude
				 horizontalAccuracy:aLocation.horizontalAccuracy
				   verticalAccuracy:aLocation.verticalAccuracy
						  timestamp:aTimestamp];
#endif
}


@end

