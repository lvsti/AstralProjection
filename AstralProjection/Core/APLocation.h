//
//  APLocation.h
//  AstralProjection
//
//  Created by Lvsti on 2010.10.10..
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>


@interface APLocation : CLLocation
#if !TARGET_OS_IPHONE
{
	CLLocationSpeed apSpeed;
	CLLocationDirection apCourse;
}

@property (assign, NS_NONATOMIC_IPHONEONLY) CLLocationSpeed speed;
@property (assign, NS_NONATOMIC_IPHONEONLY) CLLocationDirection course;

- (id)initWithCoordinate:(CLLocationCoordinate2D)aCoordinate
				altitude:(CLLocationDistance)aAltitude
	  horizontalAccuracy:(CLLocationAccuracy)aHAccuracy
		verticalAccuracy:(CLLocationAccuracy)aVAccuracy
				  course:(CLLocationDirection)aCourse
				   speed:(CLLocationSpeed)aSpeed
			   timestamp:(NSDate*)aTimestamp;

#endif

@end
