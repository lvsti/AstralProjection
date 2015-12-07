//
//  APHeading.h
//  AstralProjection
//
//  Created by Lkxf on 2011.02.03..
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLHeading.h>

@interface APHeading : NSObject <NSCopying, NSCoding>

@property(nonatomic, assign, readonly) CLLocationDirection magneticHeading;
@property(nonatomic, assign, readonly) CLLocationDirection trueHeading;
@property(nonatomic, assign, readonly) CLLocationDirection headingAccuracy;
@property(nonatomic, assign, readonly) CLHeadingComponentValue x;
@property(nonatomic, assign, readonly) CLHeadingComponentValue y;
@property(nonatomic, assign, readonly) CLHeadingComponentValue z;
@property(nonatomic, copy, readonly) NSDate* timestamp;

- (APHeading*)initWithMagneticHeading:(CLLocationDirection)aMagneticHeading
						  trueHeading:(CLLocationDirection)aTrueHeading
							 accuracy:(CLLocationDirection)aAccuracy
									x:(CLHeadingComponentValue)aX
									y:(CLHeadingComponentValue)aY
									z:(CLHeadingComponentValue)aZ
							timestamp:(NSDate*)aTimestamp;

@end

