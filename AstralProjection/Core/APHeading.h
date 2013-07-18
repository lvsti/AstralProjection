//
//  APHeading.h
//  AstralProjection
//
//  Created by Lkxf on 2010.10.10..
//

#import <Foundation/Foundation.h>
#import "EXT_CLHeading.h"


@interface APHeading : CLHeading

@property (nonatomic) CLLocationDirection magneticHeading;
@property (nonatomic) CLLocationDirection trueHeading;
@property (nonatomic) CLLocationDirection headingAccuracy;
@property (nonatomic, retain) NSDate* timestamp;

@property (nonatomic) CLHeadingComponentValue x;
@property (nonatomic) CLHeadingComponentValue y;
@property (nonatomic) CLHeadingComponentValue z;


@end
