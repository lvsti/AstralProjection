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
@property(nonatomic, assign, readwrite) CLLocationDirection magneticHeading;
@property(nonatomic, assign, readwrite) CLLocationDirection trueHeading;
@property(nonatomic, assign, readwrite) CLLocationDirection headingAccuracy;
@property(nonatomic, assign, readwrite) CLHeadingComponentValue x;
@property(nonatomic, assign, readwrite) CLHeadingComponentValue y;
@property(nonatomic, assign, readwrite) CLHeadingComponentValue z;
@property(nonatomic, copy, readwrite) NSDate* timestamp;
@end



@implementation APHeading

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
		_magneticHeading = aMagneticHeading;
		_trueHeading = aTrueHeading;
		_headingAccuracy = aAccuracy;
		_x = aX;
		_y = aY;
		_z = aZ;
        _timestamp = [aTimestamp copy];
	}
	
	return self;
}


- (id)copyWithZone:(NSZone*)aZone
{
    APHeading* headingCopy = [APHeading new];
	if (headingCopy)
	{
		headingCopy.magneticHeading = self.magneticHeading;
		headingCopy.trueHeading = self.trueHeading;
		headingCopy.headingAccuracy = self.headingAccuracy;
		headingCopy.x = self.x;
		headingCopy.y = self.y;
		headingCopy.z = self.z;
        headingCopy.timestamp = [self.timestamp copy];
	}
	
	return headingCopy;
}


- (id)initWithCoder:(NSCoder*)aDecoder
{
    [NSException raise:NSInvalidUnarchiveOperationException
                format:@"APHeading unarchiving not implemented"];
	return nil;
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


