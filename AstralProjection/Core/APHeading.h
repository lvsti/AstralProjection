//
//  APHeading.h
//  AstralProjection
//
//  Created by Lvsti on 2010.10.10..
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLHeading.h>


@interface APHeading : CLHeading
{
	CLLocationDirection apMagneticHeading;
	CLLocationDirection apTrueHeading;
	CLLocationDirection apHeadingAccuracy;
	NSDate* apTimestamp;
	CLHeadingComponentValue apX;
	CLHeadingComponentValue apY;
	CLHeadingComponentValue apZ;
}

@property (nonatomic, assign) CLLocationDirection magneticHeading;
@property (nonatomic, assign) CLLocationDirection trueHeading;
@property (nonatomic, assign) CLLocationDirection headingAccuracy;
@property (nonatomic, assign) NSDate* timestamp;

@property (nonatomic, assign) CLHeadingComponentValue x;
@property (nonatomic, assign) CLHeadingComponentValue y;
@property (nonatomic, assign) CLHeadingComponentValue z;


@end
