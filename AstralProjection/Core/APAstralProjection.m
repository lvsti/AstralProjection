//
//  APAstralProjection.m
//  APDesktopHost
//
//  Created by Tamas Lustyik on 2013.07.18..
//  Copyright (c) 2013 LKXF Studios. All rights reserved.
//

#import "APAstralProjection.h"
#import <objc/runtime.h>
#import "APLocationDataSource.h"
#import "APHeadingDataSource.h"
#import "APLocationDataDelegate.h"
#import "APHeadingDataDelegate.h"


static NSString* const kLastRegisteredValueKey = @"lastValue";
static NSString* const kCallbackThreadKey = @"thread";


@interface APAstralProjection () <APLocationDataDelegate, APHeadingDataDelegate>
{
	id<APLocationDataSource> activeLds;
	id<APHeadingDataSource> activeHds;
	
	NSMutableDictionary* locationListeners;
	NSMutableDictionary* headingListeners;
}

- (void)startUpdatingLocationForManager:(CLLocationManager*)aManager;
- (void)stopUpdatingLocationForManager:(CLLocationManager*)aManager;

- (void)startUpdatingHeadingForManager:(CLLocationManager*)aManager;
- (void)stopUpdatingHeadingForManager:(CLLocationManager*)aManager;

- (CLLocation*)lastRegisteredLocationForManager:(CLLocationManager*)aManager;
- (CLLocation*)lastRegisteredHeadingForManager:(CLLocationManager*)aManager;

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
	
	for ( int i = 0; i < swizzledMethodCount; ++i )
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
	return [apSharedInstance lastRegisteredLocationForManager:self];
}


- (CLLocation*)heading
{
	return [apSharedInstance lastRegisteredHeadingForManager:self];
}


@end



#pragma clang diagnostic pop





@implementation APAstralProjection

@synthesize delegate;
@synthesize locationDataSource;
@synthesize headingDataSource;


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
	delegate = aDelegate;
	apDelegate = aDelegate;
}


- (id)init
{
	self = [super init];
	if (self)
	{
		locationListeners = [[NSMutableDictionary alloc] init];
		headingListeners = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}


- (void)dealloc
{
	[locationListeners release];
	[headingListeners release];
	[super dealloc];
}


- (void)startUpdatingLocationForManager:(CLLocationManager*)aManager
{
	NSValue* wrapper = [NSValue valueWithNonretainedObject:aManager];
	
	if ( !locationDataSource || [locationListeners objectForKey:wrapper] )
	{
		// nothing to do
		return;
	}
	
	activeLds = [locationDataSource retain];
	activeLds.locationDataDelegate = self;
	[locationListeners setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
								  [NSValue valueWithNonretainedObject:[NSThread currentThread]], kCallbackThreadKey,
								  nil]
						  forKey:wrapper];
}


- (void)stopUpdatingLocationForManager:(CLLocationManager*)aManager
{
	NSValue* wrapper = [NSValue valueWithNonretainedObject:aManager];

	if ( ![locationListeners objectForKey:wrapper] )
	{
		// nothing to do
		return;
	}
	
	[locationListeners removeObjectForKey:wrapper];

	if ( [locationListeners count] == 0 )
	{
		activeLds.locationDataDelegate = nil;
		[activeLds release];
		activeLds = nil;
	}
	else
	{
		[activeLds release];
	}
}


- (void)startUpdatingHeadingForManager:(CLLocationManager*)aManager
{
	NSValue* wrapper = [NSValue valueWithNonretainedObject:aManager];

	if ( !headingDataSource || [headingListeners objectForKey:wrapper] )
	{
		// nothing to do
		return;
	}
	
	activeHds = [headingDataSource retain];
	activeHds.headingDataDelegate = self;
	[headingListeners setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
								 [NSValue valueWithNonretainedObject:[NSThread currentThread]], kCallbackThreadKey,
								 nil]
						 forKey:wrapper];
}


- (void)stopUpdatingHeadingForManager:(CLLocationManager*)aManager
{
	NSValue* wrapper = [NSValue valueWithNonretainedObject:aManager];

	if ( ![headingListeners objectForKey:wrapper] )
	{
		// nothing to do
		return;
	}
	
	[headingListeners removeObjectForKey:wrapper];

	if ( [headingListeners count] == 0 )
	{
		activeHds.headingDataDelegate = nil;
		[activeHds release];
		activeHds = nil;
	}
	else
	{
		[activeHds release];
	}
}


- (CLLocation*)lastRegisteredLocationForManager:(CLLocationManager*)aManager
{
	NSDictionary* record = [locationListeners objectForKey:[NSValue valueWithNonretainedObject:aManager]];
	return [record objectForKey:kLastRegisteredValueKey];
}


- (CLLocation*)lastRegisteredHeadingForManager:(CLLocationManager*)aManager
{
	NSDictionary* record = [headingListeners objectForKey:[NSValue valueWithNonretainedObject:aManager]];
	return [record objectForKey:kLastRegisteredValueKey];
}


#pragma mark - from APLocationDataDelegate:


// -----------------------------------------------------------------------------
// APAstralProjection::locationDataSource:didUpdateToLocation:fromLocation:
// -----------------------------------------------------------------------------
- (void)locationDataSource:(id<APLocationDataSource>)aDataSource
	   didUpdateToLocation:(CLLocation*)aNewLocation
			  fromLocation:(CLLocation*)aOldLocation
{
	if ( [CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized ||
		 ![CLLocationManager locationServicesEnabled] )
	{
		return;
	}
	
	[locationListeners enumerateKeysAndObjectsUsingBlock:^(id key, NSMutableDictionary* obj, BOOL *stop) {
		CLLocationManager* locMgr = [key nonretainedObjectValue];
		
		CLLocation* lastLocation = [obj objectForKey:kLastRegisteredValueKey];
		if ( !lastLocation ||
			 locMgr.distanceFilter == kCLDistanceFilterNone ||
			 [aNewLocation distanceFromLocation:lastLocation] >= ABS(locMgr.distanceFilter) )
		{
			[obj setObject:aNewLocation forKey:kLastRegisteredValueKey];
			
			NSThread* callbackThread = [[obj objectForKey:kCallbackThreadKey] nonretainedObjectValue];
			if ( callbackThread == [NSThread currentThread] )
			{
				if ( [locMgr.delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)] )
				{
					[locMgr.delegate performSelector:@selector(locationManager:didUpdateLocations:)
										  withObject:self
										  withObject:[NSArray arrayWithObject:aNewLocation]];
				}
				else if ( [locMgr.delegate respondsToSelector:@selector(locationManager:didUpdateToLocation:fromLocation:)] )
				{
					// deprecated method
					[locMgr.delegate locationManager:locMgr
								 didUpdateToLocation:aNewLocation
										fromLocation:aOldLocation];
				}
			}
			else
			{
				[self performSelector:@selector(updateLocationDelegateWithData:)
							 onThread:callbackThread
						   withObject:[NSArray arrayWithObjects:locMgr,aNewLocation,aOldLocation,nil]
						waitUntilDone:YES];
			}
		}
	}];
}


// -----------------------------------------------------------------------------
// APAstralProjection::updateLocationDelegateWithData:
// -----------------------------------------------------------------------------
- (void)updateLocationDelegateWithData:(NSArray*)aLocationData
{
	CLLocationManager* locMgr = [aLocationData objectAtIndex:0];
	if ( [locMgr.delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)] )
	{
		[locMgr.delegate performSelector:@selector(locationManager:didUpdateLocations:)
							  withObject:locMgr
							  withObject:[NSArray arrayWithObject:[aLocationData objectAtIndex:1]]];
	}
	else
	{
		// deprecated method
		[locMgr.delegate locationManager:locMgr
					 didUpdateToLocation:[aLocationData objectAtIndex:1]
							fromLocation:([aLocationData count]>2)? [aLocationData objectAtIndex:2]: nil];
	}
}


// -----------------------------------------------------------------------------
// APAstralProjection::locationDataSource:didFailToUpdateLocationWithError:
// -----------------------------------------------------------------------------
- (void)locationDataSource:(id<APLocationDataSource>)aDataSource
	didFailToUpdateLocationWithError:(NSError*)aError
{
	[locationListeners enumerateKeysAndObjectsUsingBlock:^(id key, NSMutableDictionary* obj, BOOL *stop) {
		CLLocationManager* locMgr = [key nonretainedObjectValue];

		if ( [locMgr.delegate respondsToSelector:@selector(locationManager:didFailWithError:)] )
		{
			NSThread* callbackThread = [[obj objectForKey:kCallbackThreadKey] nonretainedObjectValue];
			if ( callbackThread == [NSThread currentThread] )
			{
				[locMgr.delegate locationManager:locMgr
								didFailWithError:aError];
			}
			else
			{
				[self performSelector:@selector(updateLocationDelegateWithError:)
							 onThread:callbackThread
						   withObject:[NSArray arrayWithObjects:locMgr, aError, nil]
						waitUntilDone:YES];
			}
		}
	}];
}


// -----------------------------------------------------------------------------
// APAstralProjection::updateLocationDelegateWithError:
// -----------------------------------------------------------------------------
- (void)updateLocationDelegateWithError:(NSArray*)aLocationData
{
	CLLocationManager* locMgr = [aLocationData objectAtIndex:0];
	[locMgr.delegate locationManager:locMgr
					didFailWithError:[aLocationData objectAtIndex:1]];
}


#pragma mark - from APHeadingDataDelegate:


// -----------------------------------------------------------------------------
// APAstralProjection::headingDataSource:didUpdateToHeading:
// -----------------------------------------------------------------------------
- (void)headingDataSource:(id<APHeadingDataSource>)aDataSource
	   didUpdateToHeading:(CLHeading*)aNewHeading
{
	if ( [CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized ||
		 ![CLLocationManager locationServicesEnabled] ||
		 ![CLLocationManager headingAvailable] )
	{
		return;
	}
	
#if AP_HEADING_AVAILABLE
	[headingListeners enumerateKeysAndObjectsUsingBlock:^(id key, NSMutableDictionary* obj, BOOL *stop) {
		CLLocationManager* locMgr = [key nonretainedObjectValue];
		
		CLHeading* lastHeading = [obj objectForKey:kLastRegisteredValueKey];
		if ( !lastHeading ||
			 locMgr.headingFilter == kCLHeadingFilterNone ||
			 ABS(aNewHeading.magneticHeading - lastHeading.magneticHeading) >= ABS(locMgr.headingFilter) )
		{
			[obj setObject:aNewHeading forKey:kLastRegisteredValueKey];
			
			if ( [locMgr.delegate respondsToSelector:@selector(locationManager:didUpdateHeading:)] )
			{
				NSThread* callbackThread = [[obj objectForKey:kCallbackThreadKey] nonretainedObjectValue];
				if ( callbackThread == [NSThread currentThread] )
				{
					[locMgr.delegate performSelector:@selector(locationManager:didUpdateHeading:)
										  withObject:locMgr
										  withObject:aNewHeading];
				}
				else
				{
					[self performSelector:@selector(updateHeadingDelegateWithHeading:)
								 onThread:callbackThread
							   withObject:[NSArray arrayWithObjects:locMgr, aNewHeading, nil]
							waitUntilDone:YES];
				}
			}
		}
	}];
#endif
}


// -----------------------------------------------------------------------------
// APLocationManager::updateHeadingDelegateWithData:
// -----------------------------------------------------------------------------
- (void)updateHeadingDelegateWithData:(NSArray*)aHeadingData
{
	CLLocationManager* locMgr = [aHeadingData objectAtIndex:0];
	[locMgr.delegate performSelector:@selector(locationManager:didUpdateHeading:)
						  withObject:locMgr
						  withObject:[aHeadingData objectAtIndex:1]];
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


