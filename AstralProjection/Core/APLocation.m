//
//  APLocation.m
//  AstralProjection
//
//  Created by Lvsti on 2010.10.10..
//

#import "APLocation.h"

static NSString* const kLocationDescriptionFormat = @"<%+3.8f, %+3.8f> +/- %4.2fm (speed %4.2f mps / course %3.2f) @ %@";


@implementation APLocation

@synthesize speed = apSpeed;
@synthesize course = apCourse;


// -----------------------------------------------------------------------------
// APLocation::description
// -----------------------------------------------------------------------------
- (NSString*)description
{
	return [NSString stringWithFormat:kLocationDescriptionFormat,
			self.coordinate.latitude,
			self.coordinate.longitude,
			self.horizontalAccuracy,
			self.speed,
			self.course,
			self.timestamp];
}

@end
