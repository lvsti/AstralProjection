//
//  CLLocation+AstralProjection.m
//  APDesktopHost
//
//  Created by Tamas Lustyik on 2013.07.19..
//  Copyright (c) 2013 LKXF Studios. All rights reserved.
//

#import "CLLocation+AstralProjection.h"
#import <objc/runtime.h>


static const char* kAP_CLLocation_timestampKey = "ap_timestamp";

static IMP CLLocation_timestamp = NULL;


id AP_CLLocation_timestamp(id aSelf, SEL aCmd)
{
	id obj = objc_getAssociatedObject(aSelf, kAP_CLLocation_timestampKey);
	return obj? obj: CLLocation_timestamp(aSelf, aCmd);
}



@implementation CLLocation (AstralProjection)

+ (void)load
{
	Method m = class_getInstanceMethod([self class], @selector(timestamp));
	CLLocation_timestamp = method_setImplementation(m, (IMP)AP_CLLocation_timestamp);
}

- (void)setTimestamp:(NSDate*)aTimestamp
{
	objc_setAssociatedObject(self, kAP_CLLocation_timestampKey, aTimestamp, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

