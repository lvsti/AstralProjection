//
//  APAstralProjection.h
//  APDesktopHost
//
//  Created by Tamas Lustyik on 2013.07.18..
//  Copyright (c) 2013 LKXF Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol APLocationDataSource;
@protocol APHeadingDataSource;


@protocol APAstralProjectionDelegate <NSObject>

@optional
- (CLAuthorizationStatus)astralAuthorizationStatus;
- (BOOL)astralLocationServicesEnabled;
- (BOOL)astralDeferredLocationUpdatesAvailable;
- (BOOL)astralSignificantLocationChangeMonitoringAvailable;
- (BOOL)astralHeadingAvailable;
- (BOOL)astralRegionMonitoringAvailable;

@end


@interface APAstralProjection : NSObject

@property (nonatomic, assign) id<APAstralProjectionDelegate> delegate;
@property (nonatomic, assign) id<APLocationDataSource> locationDataSource;
@property (nonatomic, assign) id<APHeadingDataSource> headingDataSource;

+ (APAstralProjection*)sharedInstance;

@end
