//
//  APLocation.h
//  AstralProjection
//
//  Created by Lvsti on 2010.10.10..
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>


@interface APLocation : CLLocation
{
	CLLocationSpeed apSpeed;
	CLLocationDirection apCourse;
}

@property(NS_NONATOMIC_IPHONEONLY, assign) CLLocationSpeed speed;
@property(NS_NONATOMIC_IPHONEONLY, assign) CLLocationDirection course;

@end
