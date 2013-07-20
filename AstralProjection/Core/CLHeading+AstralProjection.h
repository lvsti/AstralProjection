//
//  CLHeading+AstralProjection.h
//  APDesktopHost
//
//  Created by Tamas Lustyik on 2013.07.19..
//  Copyright (c) 2013 LKXF Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EXT_CLHeading.h"

@interface CLHeading (AstralProjection)

+ (CLHeading*)headingWithMagneticHeading:(CLLocationDirection)aMagneticHeading
							 trueHeading:(CLLocationDirection)aTrueHeading
								accuracy:(CLLocationDirection)aAccuracy
							   timestamp:(NSDate*)aTimestamp
									   x:(CLHeadingComponentValue)aX
									   y:(CLHeadingComponentValue)aY
									   z:(CLHeadingComponentValue)aZ;

- (void)setTimestamp:(NSDate*)aTimestamp;

@end
