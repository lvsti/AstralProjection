//
//  APHeading.m
//  AstralProjection
//
//  Created by Lkxf on 2011.02.03..
//


#import "APHeading.h"


#if !TARGET_OS_IPHONE && __MAC_OS_X_VERSION_MAX_ALLOWED <= __MAC_10_6

const CLLocationDegrees kCLHeadingFilterNone = -1.0;

#endif

NSString* const kAPHeadingDescriptionFormat = @"magneticHeading %3.2f trueHeading %3.2f accuracy %3.2f x %3.3f y %3.3f z %3.3f @ %@";


@interface APHeading ()
{
	CLLocationDirection magneticHeading;
	CLLocationDirection trueHeading;
	CLLocationDirection headingAccuracy;
	CLHeadingComponentValue x;
	CLHeadingComponentValue y;
	CLHeadingComponentValue z;
}
@end



@implementation APHeading

@synthesize magneticHeading;
@synthesize trueHeading;
@synthesize headingAccuracy;
@synthesize x;
@synthesize y;
@synthesize z;
@synthesize timestamp;


- (APHeading*)initWithMagneticHeading:(CLLocationDirection)aMagneticHeading
						  trueHeading:(CLLocationDirection)aTrueHeading
							 accuracy:(CLLocationDirection)aAccuracy
									x:(CLHeadingComponentValue)aX
									y:(CLHeadingComponentValue)aY
									z:(CLHeadingComponentValue)aZ
							timestamp:(NSDate*)aTimestamp
{
	self = [super init];
	
	if (self)
	{
		magneticHeading = aMagneticHeading;
		trueHeading = aTrueHeading;
		headingAccuracy = aAccuracy;
		x = aX;
		y = aY;
		z = aZ;
		timestamp = [aTimestamp retain];
	}
	
	return self;
}


- (void)dealloc
{
	[timestamp release];
	[super dealloc];
}


- (id)copyWithZone:(NSZone*)aZone
{
	APHeading* headingCopy = [[[self class] allocWithZone:aZone] init];
	if ( headingCopy )
	{
		headingCopy->magneticHeading = magneticHeading;
		headingCopy->trueHeading = trueHeading;
		headingCopy->headingAccuracy = headingAccuracy;
		headingCopy->x = x;
		headingCopy->y = y;
		headingCopy->z = z;
		headingCopy->timestamp = [timestamp retain];
	}
	
	return headingCopy;
}


- (id)initWithCoder:(NSCoder*)aDecoder
{
	if ( (self = [super init]) )
	{
		[NSException raise:NSInvalidUnarchiveOperationException
					format:@"APHeading unarchiving not implemented"];
		// TODO: implementation
	}
	
	return self;
}


- (void)encodeWithCoder:(NSCoder*)aCoder
{
	[NSException raise:NSInvalidArchiveOperationException
				format:@"APHeading archiving not implemented"];
	// TODO: implementation
}


- (NSString*)description
{
	return [NSString stringWithFormat:kAPHeadingDescriptionFormat,
			self.magneticHeading,
			self.trueHeading,
			self.headingAccuracy,
			self.x,
			self.y,
			self.z,
			self.timestamp];
}

@end


