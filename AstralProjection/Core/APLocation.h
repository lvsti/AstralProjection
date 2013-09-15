//
//  APLocation.h
//  AstralProjection
//
//  Created by Lkxf on 2011.02.03..
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>


#if !TARGET_OS_IPHONE && __MAC_OS_X_VERSION_MIN_REQUIRED <= __MAC_10_6

extern CLLocationCoordinate2D CLLocationCoordinate2DMake(CLLocationDegrees latitude,
														 CLLocationDegrees longitude);

#endif


@compatibility_alias APLocation CLLocation;

@interface CLLocation (AstralProjection)

- (id)initWithLocation:(APLocation*)aLocation
		     timestamp:(NSDate*)aTimestamp;

@end

