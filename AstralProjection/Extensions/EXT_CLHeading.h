//
//  EXT_CLHeading.h
//  AstralProjection
//
//  Created by Lkxf on 2011.02.03..
//


#if TARGET_OS_IPHONE || __MAC_OS_X_VERSION_MAX_ALLOWED > __MAC_10_6

#import <CoreLocation/CLHeading.h>

#else

#import <CoreLocation/CLLocation.h>
#import <Foundation/Foundation.h>

typedef double CLHeadingComponentValue;

extern const CLLocationDegrees kCLHeadingFilterNone;

@interface CLHeading : NSObject <NSCopying, NSCoding>

@property(readonly, nonatomic) CLLocationDirection magneticHeading;
@property(readonly, nonatomic) CLLocationDirection trueHeading;
@property(readonly, nonatomic) CLLocationDirection headingAccuracy;
@property(readonly, nonatomic) CLHeadingComponentValue x;
@property(readonly, nonatomic) CLHeadingComponentValue y;
@property(readonly, nonatomic) CLHeadingComponentValue z;
@property(readonly, nonatomic, retain) NSDate* timestamp;

- (NSString*)description;

@end

#endif

