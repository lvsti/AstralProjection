//
//  APAstralProjection.m
//  APDesktopHost
//
//  Created by Tamas Lustyik on 2013.07.18..
//  Copyright (c) 2013 LKXF Studios. All rights reserved.
//

#import "APAstralProjection.h"
#import <objc/runtime.h>
#import "APHeadingDataDelegate.h"
#import "APHeadingDataSource.h"
#import "APLocationDataDelegate.h"
#import "APLocationDataSource.h"


static NSString* const kLastRegisteredValueKey = @"lastValue";
static NSString* const kCallbackThreadKey = @"thread";


@interface APAstralProjection () <APLocationDataDelegate, APHeadingDataDelegate>
{
	id<APLocationDataSource> _activeLds;
	id<APHeadingDataSource> _activeHds;
	
	NSMutableDictionary* _locationListeners;
	NSMutableDictionary* _headingListeners;
}

- (void)startUpdatingLocationForManager:(CLLocationManager*)aManager;
- (void)stopUpdatingLocationForManager:(CLLocationManager*)aManager;

- (void)startUpdatingHeadingForManager:(CLLocationManager*)aManager;
- (void)stopUpdatingHeadingForManager:(CLLocationManager*)aManager;

- (APLocation*)lastRegisteredLocationForManager:(CLLocationManager*)aManager;
- (APHeading*)lastRegisteredHeadingForManager:(CLLocationManager*)aManager;

@end

static APAstralProjection* apSharedInstance = nil;
static id<APAstralProjectionDelegate> apDelegate = nil;


// CLLocationManager class methods
static IMP CLLocationManager_authorizationStatus = NULL;
static IMP CLLocationManager_locationServicesEnabled = NULL;
static IMP CLLocationManager_significantLocationChangeMonitoringAvailable = NULL;
static IMP CLLocationManager_headingAvailable = NULL;
static IMP CLLocationManager_regionMonitoringAvailable = NULL;
#if TARGET_OS_IPHONE
static IMP CLLocationManager_deferredLocationUpdatesAvailable = NULL;
#endif


// -----------------------------------------------------------------------------
// alternative implementations for the CLLocationManager class methods
// -----------------------------------------------------------------------------

CLAuthorizationStatus AP_CLLocationManager_authorizationStatus(id aSelf, SEL aCmd)
{
	return [apDelegate respondsToSelector:@selector(astralAuthorizationStatus)]? [apDelegate astralAuthorizationStatus]: ((CLAuthorizationStatus(*)(id,SEL))CLLocationManager_authorizationStatus)(aSelf,aCmd);
}


BOOL AP_CLLocationManager_locationServicesEnabled(id aSelf, SEL aCmd)
{
	return [apDelegate respondsToSelector:@selector(astralLocationServicesEnabled)]? [apDelegate astralLocationServicesEnabled]: ((BOOL(*)(id,SEL))CLLocationManager_locationServicesEnabled)(aSelf,aCmd);
}


BOOL AP_CLLocationManager_significantLocationChangeMonitoringAvailable(id aSelf, SEL aCmd)
{
	return [apDelegate respondsToSelector:@selector(astralSignificantLocationChangeMonitoringAvailable)]? [apDelegate astralSignificantLocationChangeMonitoringAvailable]: ((BOOL(*)(id,SEL))CLLocationManager_significantLocationChangeMonitoringAvailable)(aSelf,aCmd);
}


BOOL AP_CLLocationManager_headingAvailable(id aSelf, SEL aCmd)
{
	return [apDelegate respondsToSelector:@selector(astralHeadingAvailable)]? [apDelegate astralHeadingAvailable]: ((BOOL(*)(id,SEL))CLLocationManager_headingAvailable)(aSelf,aCmd);
}


BOOL AP_CLLocationManager_regionMonitoringAvailable(id aSelf, SEL aCmd)
{
	return [apDelegate respondsToSelector:@selector(astralRegionMonitoringAvailable)]? [apDelegate astralRegionMonitoringAvailable]: ((BOOL(*)(id,SEL))CLLocationManager_regionMonitoringAvailable)(aSelf,aCmd);
}


#if TARGET_OS_IPHONE
// this method is only available on iOS
BOOL AP_CLLocationManager_deferredLocationUpdatesAvailable(id aSelf, SEL aCmd)
{
	return [apDelegate respondsToSelector:@selector(astralDeferredLocationUpdatesAvailable)]? [apDelegate astralDeferredLocationUpdatesAvailable]: ((BOOL(*)(id,SEL))CLLocationManager_deferredLocationUpdatesAvailable)(aSelf,aCmd);
}
#endif


// -----------------------------------------------------------------------------
// CLLocationManager class method swizzling
// -----------------------------------------------------------------------------
typedef struct { char* selectorName; IMP* original; IMP override; } APMethodSwizzle;

#define AP_METHOD_SWIZZLE(sel)	{ #sel, &CLLocationManager_##sel, (IMP)AP_CLLocationManager_##sel }
static APMethodSwizzle swizzledClassMethods[] =
{
	AP_METHOD_SWIZZLE(authorizationStatus),
	AP_METHOD_SWIZZLE(locationServicesEnabled),
	AP_METHOD_SWIZZLE(significantLocationChangeMonitoringAvailable),
	AP_METHOD_SWIZZLE(headingAvailable),
	AP_METHOD_SWIZZLE(regionMonitoringAvailable),
#if TARGET_OS_IPHONE
	AP_METHOD_SWIZZLE(deferredLocationUpdatesAvailable), 	// this method is only available on iOS
#endif
};
#undef AP_METHOD_SWIZZLE


// silence category warnings
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"


@implementation CLLocationManager (AstralProjection)

+ (void)load
{
	// override class methods
	Class locMgrClass = [CLLocationManager class];
	Method m;
	int swizzledMethodCount = sizeof(swizzledClassMethods)/sizeof(swizzledClassMethods[0]);
	
	for (int i = 0; i < swizzledMethodCount; ++i)
	{
		m = class_getClassMethod(locMgrClass, sel_registerName(swizzledClassMethods[i].selectorName));
		*swizzledClassMethods[i].original = method_setImplementation(m, swizzledClassMethods[i].override);
	}
}


- (void)startUpdatingLocation
{
	[apSharedInstance startUpdatingLocationForManager:self];
}


- (void)stopUpdatingLocation
{
	[apSharedInstance stopUpdatingLocationForManager:self];
}


- (void)startUpdatingHeading
{
	[apSharedInstance startUpdatingHeadingForManager:self];
}


- (void)stopUpdatingHeading
{
	[apSharedInstance stopUpdatingHeadingForManager:self];
}


- (CLLocation*)location
{
	return (CLLocation*)[apSharedInstance lastRegisteredLocationForManager:self];
}


- (CLHeading*)heading
{
	return (CLHeading*)[apSharedInstance lastRegisteredHeadingForManager:self];
}


@end


#pragma clang diagnostic pop



@implementation APAstralProjection


+ (void)initialize
{
	apSharedInstance = [[APAstralProjection alloc] init];
}


+ (APAstralProjection*)sharedInstance
{
	return apSharedInstance;
}


- (void)setDelegate:(id<APAstralProjectionDelegate>)aDelegate
{
	_delegate = aDelegate;
	apDelegate = aDelegate;
}


- (id)init
{
	self = [super init];
	if (self)
	{
		_locationListeners = [NSMutableDictionary new];
		_headingListeners = [NSMutableDictionary new];
	}
	
	return self;
}


- (void)startUpdatingLocationForManager:(CLLocationManager*)aManager
{
	NSValue* wrapper = [NSValue valueWithNonretainedObject:aManager];
	
	if (!_locationDataSource || _locationListeners[wrapper])
	{
		// nothing to do
		return;
	}
	
	_activeLds = _locationDataSource;
	_activeLds.locationDataDelegate = self;
    _locationListeners[wrapper] = [@{ kCallbackThreadKey: [NSValue valueWithNonretainedObject:[NSThread currentThread]] } mutableCopy];
}


- (void)stopUpdatingLocationForManager:(CLLocationManager*)aManager
{
	NSValue* wrapper = [NSValue valueWithNonretainedObject:aManager];

	if (!_locationListeners[wrapper])
	{
		// nothing to do
		return;
	}
	
	[_locationListeners removeObjectForKey:wrapper];

	if (_locationListeners.count == 0)
	{
		_activeLds.locationDataDelegate = nil;
		_activeLds = nil;
	}
}


- (void)startUpdatingHeadingForManager:(CLLocationManager*)aManager
{
	NSValue* wrapper = [NSValue valueWithNonretainedObject:aManager];

	if (!_headingDataSource || _headingListeners[wrapper])
	{
		// nothing to do
		return;
	}
	
    _activeHds = _headingDataSource;
	_activeHds.headingDataDelegate = self;
    _headingListeners[wrapper] = [@{ kCallbackThreadKey: [NSValue valueWithNonretainedObject:[NSThread currentThread]] } mutableCopy];
}


- (void)stopUpdatingHeadingForManager:(CLLocationManager*)aManager
{
	NSValue* wrapper = [NSValue valueWithNonretainedObject:aManager];

	if (!_headingListeners[wrapper])
	{
		// nothing to do
		return;
	}
	
	[_headingListeners removeObjectForKey:wrapper];

	if (_headingListeners.count == 0)
	{
		_activeHds.headingDataDelegate = nil;
		_activeHds = nil;
	}
}


- (APLocation*)lastRegisteredLocationForManager:(CLLocationManager*)aManager
{
	NSDictionary* record = _locationListeners[[NSValue valueWithNonretainedObject:aManager]];
	return record[kLastRegisteredValueKey];
}


- (APHeading*)lastRegisteredHeadingForManager:(CLLocationManager*)aManager
{
	NSDictionary* record = _headingListeners[[NSValue valueWithNonretainedObject:aManager]];
	return record[kLastRegisteredValueKey];
}


#pragma mark - from APLocationDataDelegate:


- (void)locationDataSource:(id<APLocationDataSource>)aDataSource
	   didUpdateToLocation:(APLocation*)aNewLocation
			  fromLocation:(APLocation*)aOldLocation
{
	if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized ||
		![CLLocationManager locationServicesEnabled])
	{
		return;
	}
	
	NSDictionary* currentListeners = [_locationListeners copy];
	
	[currentListeners enumerateKeysAndObjectsUsingBlock:^(NSValue* key, NSMutableDictionary* obj, BOOL *stop) {
		CLLocationManager* locMgr = key.nonretainedObjectValue;
		
		APLocation* lastLocation = obj[kLastRegisteredValueKey];
		if (!lastLocation ||
			locMgr.distanceFilter == kCLDistanceFilterNone ||
			[aNewLocation distanceFromLocation:lastLocation] >= ABS(locMgr.distanceFilter))
		{
            obj[kLastRegisteredValueKey] = aNewLocation;
			
			NSThread* callbackThread = [obj[kCallbackThreadKey] nonretainedObjectValue];
			if (callbackThread == [NSThread currentThread])
			{
				if ([locMgr.delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)])
				{
					[locMgr.delegate performSelector:@selector(locationManager:didUpdateLocations:)
										  withObject:self
										  withObject:@[aNewLocation]];
				}
				else if ([locMgr.delegate respondsToSelector:@selector(locationManager:didUpdateToLocation:fromLocation:)])
				{
					// deprecated method
					[locMgr.delegate locationManager:locMgr
								 didUpdateToLocation:(CLLocation*)aNewLocation
										fromLocation:(CLLocation*)aOldLocation];
				}
			}
			else
			{
				[self performSelector:@selector(updateLocationDelegateWithData:)
							 onThread:callbackThread
                           withObject:aOldLocation? @[locMgr, aNewLocation, aOldLocation]: @[locMgr, aNewLocation]
						waitUntilDone:YES];
			}
		}
	}];
}


- (void)updateLocationDelegateWithData:(NSArray*)aLocationData
{
    CLLocationManager* locMgr = aLocationData.firstObject;
	if ([locMgr.delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)])
	{
		[locMgr.delegate performSelector:@selector(locationManager:didUpdateLocations:)
							  withObject:locMgr
							  withObject:@[aLocationData[1]]];
	}
	else
	{
		// deprecated method
		[locMgr.delegate locationManager:locMgr
					 didUpdateToLocation:aLocationData[1]
							fromLocation:(aLocationData.count > 2)? aLocationData[2]: nil];
	}
}


- (void)locationDataSource:(id<APLocationDataSource>)aDataSource
	didFailToUpdateLocationWithError:(NSError*)aError
{
	NSDictionary* currentListeners = [_locationListeners copy];
	
	[currentListeners enumerateKeysAndObjectsUsingBlock:^(NSValue* key, NSMutableDictionary* obj, BOOL *stop) {
		CLLocationManager* locMgr = key.nonretainedObjectValue;

		if ([locMgr.delegate respondsToSelector:@selector(locationManager:didFailWithError:)])
		{
			NSThread* callbackThread = [obj[kCallbackThreadKey] nonretainedObjectValue];
			if (callbackThread == [NSThread currentThread])
			{
				[locMgr.delegate locationManager:locMgr
								didFailWithError:aError];
			}
			else
			{
				[self performSelector:@selector(updateLocationDelegateWithError:)
							 onThread:callbackThread
						   withObject:@[locMgr, aError]
						waitUntilDone:YES];
			}
		}
	}];
}


- (void)updateLocationDelegateWithError:(NSArray*)aLocationData
{
    CLLocationManager* locMgr = aLocationData.firstObject;
	[locMgr.delegate locationManager:locMgr
					didFailWithError:aLocationData[1]];
}


#pragma mark - from APHeadingDataDelegate:


- (void)headingDataSource:(id<APHeadingDataSource>)aDataSource
	   didUpdateToHeading:(APHeading*)aNewHeading
{
#if TARGET_OS_IPHONE
	if ( [CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized ||
		 ![CLLocationManager locationServicesEnabled] ||
		 ![CLLocationManager headingAvailable] )
	{
		return;
	}

	NSDictionary* currentListeners = [_headingListeners copy];
	
	[currentListeners enumerateKeysAndObjectsUsingBlock:^(NSValue* key, NSMutableDictionary* obj, BOOL *stop) {
		CLLocationManager* locMgr = [key nonretainedObjectValue];
		
		APHeading* lastHeading = obj[kLastRegisteredValueKey];
		if (!lastHeading ||
			locMgr.headingFilter == kCLHeadingFilterNone ||
			ABS(aNewHeading.magneticHeading - lastHeading.magneticHeading) >= ABS(locMgr.headingFilter))
		{
            obj[kLastRegisteredValueKey] = aNewHeading;
			
			if ([locMgr.delegate respondsToSelector:@selector(locationManager:didUpdateHeading:)])
			{
				NSThread* callbackThread = [obj[kCallbackThreadKey] nonretainedObjectValue];
				if (callbackThread == [NSThread currentThread])
				{
					[locMgr.delegate performSelector:@selector(locationManager:didUpdateHeading:)
										  withObject:locMgr
										  withObject:aNewHeading];
				}
				else
				{
					[self performSelector:@selector(updateHeadingDelegateWithHeading:)
								 onThread:callbackThread
							   withObject:@[locMgr, aNewHeading]
							waitUntilDone:YES];
				}
			}
		}
	}];
#endif
}


- (void)updateHeadingDelegateWithData:(NSArray*)aHeadingData
{
    CLLocationManager* locMgr = aHeadingData.firstObject;
	[locMgr.delegate performSelector:@selector(locationManager:didUpdateHeading:)
						  withObject:locMgr
						  withObject:aHeadingData[1]];
}


@end


/*
- (void)enterAstralMode
{
	if ( isActive )
	{
		NSLog(@"WARNING: the astral session is already active");
		return;
	}
	
	isActive = YES;
	
	// override class methods
	Class locMgrClass = [CLLocationManager class];
	Method m;
	int swizzledMethodCount = sizeof(swizzledClassMethods)/sizeof(swizzledClassMethods[0]);

	for ( int i = 0; i < swizzledMethodCount; ++i )
	{
		m = class_getClassMethod(locMgrClass, sel_registerName(swizzledClassMethods[i].selectorName));
		*swizzledClassMethods[i].original = method_setImplementation(m, swizzledClassMethods[i].override);
	}
	
	// override instance methods
	m = class_getInstanceMethod(locMgrClass, @selector(startUpdatingLocation));
}


- (void)leaveAstralMode
{
	if ( !isActive )
	{
		NSLog(@"WARNING: the astral session is inactive");
		return;
	}
	
	Class locMgrClass = [CLLocationManager class];
	int swizzledMethodCount = sizeof(swizzledClassMethods)/sizeof(swizzledClassMethods[0]);
	
	for ( int i = 0; i < swizzledMethodCount; ++i )
	{
		Method m = class_getClassMethod(locMgrClass, sel_registerName(swizzledClassMethods[i].selectorName));
		method_setImplementation(m, *swizzledClassMethods[i].original);
	}
	
	isActive = NO;
}
*/


