//
//  APHeading.m
//  AstralProjection
//
//  Created by Lvsti on 2010.10.10..
//

#import "APHeading.h"

static NSString* const kHeadingDescriptionFormat = @"magneticHeading %3.2f trueHeading %3.2f accuracy %3.2f x %3.3f y %3.3f z %3.3f @ %@";


@implementation APHeading

@synthesize magneticHeading = apMagneticHeading;
@synthesize trueHeading = apTrueHeading;
@synthesize headingAccuracy = apHeadingAccuracy;
@synthesize timestamp = apTimestamp;
@synthesize x = apX;
@synthesize y = apY;
@synthesize z = apZ;


- (NSString*)description
{
	return [NSString stringWithFormat:kHeadingDescriptionFormat,
			self.magneticHeading,
			self.trueHeading,
			self.headingAccuracy,
			self.x,
			self.y,
			self.z,
			self.timestamp];
}


@end
