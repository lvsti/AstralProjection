//
//  APLocationManager.h
//  AstralProjection
//
//  Created by Lvsti on 2010.09.13..
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "APLocationDataDelegate.h"
#import "APHeadingDataDelegate.h"

#if !TARGET_OS_IPHONE
#import "EXT_CLHeading.h"
#endif


@interface APLocationManager : CLLocationManager <APLocationDataDelegate,
												  APHeadingDataDelegate>
{
	NSThread* locationThread;
	CLLocation* lastRegisteredLocation;

	NSThread* headingThread;
	CLHeading* lastRegisteredHeading;
	
#if !TARGET_OS_IPHONE
	CLLocationDegrees headingFilter;
#endif
}

@property (readonly, NS_NONATOMIC_IPHONEONLY) CLLocation* location;
@property (readonly, NS_NONATOMIC_IPHONEONLY) CLHeading* heading;

#if !TARGET_OS_IPHONE
@property (assign, NS_NONATOMIC_IPHONEONLY) CLLocationDegrees headingFilter;
#endif

@end
