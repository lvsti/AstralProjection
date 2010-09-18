//
//  APLocationManager.h
//  AstralProjection
//
//  Created by Lvsti on 2010.09.13..
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "APLocationDataDelegate.h"


@interface APLocationManager : CLLocationManager <APLocationDataDelegate>
{
	NSThread* callerThread;
	CLLocation* lastRegisteredLocation;
}

@property (readonly, nonatomic) CLLocation* location;

@end
