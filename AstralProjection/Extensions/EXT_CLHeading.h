//
//  EXT_CLHeading.h
//  AstralProjection
//
//  Created by Lvsti on 2011.02.03..
//

#import <CoreLocation/CLLocation.h>
#import <Foundation/Foundation.h>


typedef double CLHeadingComponentValue;

extern const CLLocationDegrees kCLHeadingFilterNone;

@interface CLHeading : NSObject <NSCopying, NSCoding>
{
@private
    id _internal;
}

@property(readonly, nonatomic) CLLocationDirection magneticHeading;
@property(readonly, nonatomic) CLLocationDirection trueHeading;
@property(readonly, nonatomic) CLLocationDirection headingAccuracy;
@property(readonly, nonatomic) CLHeadingComponentValue x;
@property(readonly, nonatomic) CLHeadingComponentValue y;
@property(readonly, nonatomic) CLHeadingComponentValue z;
@property(readonly, nonatomic) NSDate* timestamp;

- (NSString*)description;

@end


