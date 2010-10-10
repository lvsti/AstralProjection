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

@interface APLocationManager : CLLocationManager <APLocationDataDelegate,
												  APHeadingDataDelegate>
{
	NSThread* locationThread;
	CLLocation* lastRegisteredLocation;

	NSThread* headingThread;
	CLHeading* lastRegisteredHeading;
}

@property (readonly, nonatomic) CLLocation* location;
@property (readonly, nonatomic) CLHeading* heading;

@end
