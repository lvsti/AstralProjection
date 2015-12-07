//
//  APLocation.m
//  AstralProjection
//
//  Created by Lkxf on 2011.02.03..
//

#import "APLocation.h"


@implementation CLLocation (AstralProjection)

- (id)initWithLocation:(CLLocation*)aLocation
			 timestamp:(NSDate*)aTimestamp
{
	return [self initWithCoordinate:aLocation.coordinate
						   altitude:aLocation.altitude
				 horizontalAccuracy:aLocation.horizontalAccuracy
				   verticalAccuracy:aLocation.verticalAccuracy
							 course:aLocation.course
							  speed:aLocation.speed
						  timestamp:aTimestamp];
}


@end

