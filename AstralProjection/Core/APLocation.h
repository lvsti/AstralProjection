//
//  APLocation.h
//  AstralProjection
//
//  Created by Lkxf on 2011.02.03..
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>


@compatibility_alias APLocation CLLocation;

@interface CLLocation (AstralProjection)

- (id)initWithLocation:(APLocation*)aLocation
		     timestamp:(NSDate*)aTimestamp;

@end

