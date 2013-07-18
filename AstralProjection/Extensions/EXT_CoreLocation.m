//
//  EXT_CoreLocation.m
//  AstralProjection
//
//  Created by Lkxf on 2011.02.03..
//

#import "EXT_CoreLocation.h"

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
