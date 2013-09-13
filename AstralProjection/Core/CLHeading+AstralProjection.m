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

static IMP CLHeading_magneticHeading = NULL;
static IMP CLHeading_trueHeading = NULL;
static IMP CLHeading_headingAccuracy = NULL;
static IMP CLHeading_timestamp = NULL;
static IMP CLHeading_x = NULL;
static IMP CLHeading_y = NULL;
static IMP CLHeading_z = NULL;


#define AP_CLHEADING_PROXY(methodName,methodType)								\
methodType AP_CLHeading_##methodName(id aSelf, SEL aCmd)						\
{																				\
	id obj = objc_getAssociatedObject(aSelf, kAP_CLHeading_##methodName##Key);	\
	if (obj) { return (methodType)[(NSNumber*)obj doubleValue]; }				\
	return ((methodType(*)(id,SEL))CLHeading_##methodName)(aSelf, aCmd);		\
}

AP_CLHEADING_PROXY(magneticHeading, CLLocationDirection);
AP_CLHEADING_PROXY(trueHeading, CLLocationDirection);
AP_CLHEADING_PROXY(headingAccuracy, CLLocationDirection);
AP_CLHEADING_PROXY(x, CLHeadingComponentValue);
AP_CLHEADING_PROXY(y, CLHeadingComponentValue);
AP_CLHEADING_PROXY(z, CLHeadingComponentValue);

#undef AP_CLHEADING_PROXY


id AP_CLHeading_timestamp(id aSelf, SEL aCmd)
{
	id obj = objc_getAssociatedObject(aSelf, kAP_CLHeading_timestampKey);
	return obj? obj: CLHeading_timestamp(aSelf, aCmd);
}



@implementation CLHeading (AstralProjection)

+ (void)load
{
	Method m;
	
#define AP_CLHEADING_SWIZZLE(methodName)									\
	m = class_getInstanceMethod([self class], @selector(methodName));		\
	CLHeading_##methodName = method_setImplementation(m, (IMP)AP_CLHeading_##methodName);
	
	AP_CLHEADING_SWIZZLE(magneticHeading);
	AP_CLHEADING_SWIZZLE(trueHeading);
	AP_CLHEADING_SWIZZLE(headingAccuracy);
	AP_CLHEADING_SWIZZLE(timestamp);
	AP_CLHEADING_SWIZZLE(x);
	AP_CLHEADING_SWIZZLE(y);
	AP_CLHEADING_SWIZZLE(z);

#undef AP_CLHEADING_SWIZZLE
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

	objc_setAssociatedObject(heading, kAP_CLHeading_magneticHeadingKey, @(aMagneticHeading), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	objc_setAssociatedObject(heading, kAP_CLHeading_trueHeadingKey, @(aTrueHeading), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	objc_setAssociatedObject(heading, kAP_CLHeading_headingAccuracyKey, @(aAccuracy), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	objc_setAssociatedObject(heading, kAP_CLHeading_xKey, @(aX), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	objc_setAssociatedObject(heading, kAP_CLHeading_yKey, @(aY), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	objc_setAssociatedObject(heading, kAP_CLHeading_zKey, @(aZ), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	heading.timestamp = aTimestamp;

	return [heading autorelease];
}


- (void)setTimestamp:(NSDate*)aTimestamp
{
	objc_setAssociatedObject(self, kAP_CLHeading_timestampKey, aTimestamp, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


@end
