//
//  CLHeading+AstralProjection.m
//  APDesktopHost
//
//  Created by Tamas Lustyik on 2013.07.19..
//  Copyright (c) 2013 LKXF Studios. All rights reserved.
//

#import "CLHeading+AstralProjection.h"
#import <objc/runtime.h>


static const char* kAP_CLHeading_magneticHeadingKey = "ap_magneticHeading";
static const char* kAP_CLHeading_trueHeadingKey = "ap_trueHeading";
static const char* kAP_CLHeading_headingAccuracyKey = "ap_accuracy";
static const char* kAP_CLHeading_timestampKey = "ap_timestamp";
static const char* kAP_CLHeading_xKey = "ap_x";
static const char* kAP_CLHeading_yKey = "ap_y";
static const char* kAP_CLHeading_zKey = "ap_z";

static IMP CLHeading_timestamp = NULL;


id AP_CLHeading_timestamp(id aSelf, SEL aCmd)
{
	id obj = objc_getAssociatedObject(aSelf, kAP_CLHeading_timestampKey);
	return obj? obj: CLHeading_timestamp(aSelf, aCmd);
}



@implementation CLHeading (AstralProjection)

+ (void)load
{
	Method m = class_getInstanceMethod([self class], @selector(timestamp));
	CLHeading_timestamp = method_setImplementation(m, (IMP)AP_CLHeading_timestamp);
}


+ (CLHeading*)headingWithMagneticHeading:(CLLocationDirection)aMagneticHeading
							 trueHeading:(CLLocationDirection)aTrueHeading
								accuracy:(CLLocationDirection)aAccuracy
							   timestamp:(NSDate*)aTimestamp
									   x:(CLHeadingComponentValue)aX
									   y:(CLHeadingComponentValue)aY
									   z:(CLHeadingComponentValue)aZ
{
	CLHeading* heading = [[CLHeading alloc] init];
	
	return heading;
}


- (void)setTimestamp:(NSDate*)aTimestamp
{
	objc_setAssociatedObject(self, kAP_CLHeading_timestampKey, aTimestamp, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


@end
