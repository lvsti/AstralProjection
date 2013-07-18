//
//  APLocationManager.h
//  AstralProjection
//
//  Created by Lkxf on 2010.09.13..
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "APLocationDataDelegate.h"
#import "APHeadingDataDelegate.h"
#import "EXT_CLHeading.h"


@interface APLocationManager : CLLocationManager <APLocationDataDelegate,
												  APHeadingDataDelegate>

#if !TARGET_OS_IPHONE

#define APLOCATIONMANAGER_PROPERTY_ATOMICITY NS_NONATOMIC_IPHONEONLY

#if __MAC_OS_X_VERSION_MAX_ALLOWED > __MAC_10_6
// OSX 10.7 apparently dropped the macro and sets the property unconditionally to nonatomic
#undef APLOCATIONMANAGER_PROPERTY_ATOMICITY
#define APLOCATIONMANAGER_PROPERTY_ATOMICITY nonatomic
#endif

@property (readonly, APLOCATIONMANAGER_PROPERTY_ATOMICITY) CLHeading* heading;
@property (assign, APLOCATIONMANAGER_PROPERTY_ATOMICITY) CLLocationDegrees headingFilter;
@property (assign, APLOCATIONMANAGER_PROPERTY_ATOMICITY) CLDeviceOrientation headingOrientation;

#undef APLOCATIONMANAGER_PROPERTY_ATOMICITY

- (void)startUpdatingHeading;
- (void)stopUpdatingHeading;

#endif

@end
