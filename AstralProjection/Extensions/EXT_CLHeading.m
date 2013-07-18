//
//  EXT_CLHeading.m
//  AstralProjection
//
//  Created by Lkxf on 2011.02.03..
//


#import "EXT_CLHeading.h"


#if !TARGET_OS_IPHONE && __MAC_OS_X_VERSION_MIN_REQUIRED <= __MAC_10_6

const CLLocationDegrees kCLHeadingFilterNone = -1.0;

static NSString* const kHeadingDescriptionFormat = @"magneticHeading %3.2f trueHeading %3.2f accuracy %3.2f x %3.3f y %3.3f z %3.3f @ %@";


@implementation CLHeading

@synthesize magneticHeading;
@synthesize trueHeading;
@synthesize headingAccuracy;
@synthesize x;
@synthesize y;
@synthesize z;
@synthesize timestamp;


- (id)copyWithZone:(NSZone*)aZone
{
	CLHeading* headingCopy = NSCopyObject(self, 0, aZone);
	return headingCopy;
}


- (id)initWithCoder:(NSCoder*)aDecoder
{
	if ( (self = [super init]) )
	{
		// TODO: implementation
	}
	
	return self;
}


- (void)encodeWithCoder:(NSCoder*)aCoder
{
	// TODO: implementation
}


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

#endif
