//
//  APLocation.m
//  AstralProjection
//
//  Created by Lvsti on 2010.10.10..
//

#import "APLocation.h"

#if !TARGET_OS_IPHONE
static NSString* const kLocationDescriptionFormat = @"<%+3.8f, %+3.8f> +/- %4.2fm (speed %4.2f mps / course %3.2f) @ %@";
#endif


@implementation APLocation


@synthesize timestamp = apTimestamp;

#if !TARGET_OS_IPHONE

@synthesize speed = apSpeed;
@synthesize course = apCourse;

// -----------------------------------------------------------------------------
// APLocation::initWithCoordinate:altitude:horizontalAccuracy:verticalAccuracy:course:speed:timestamp:
// -----------------------------------------------------------------------------
- (id)initWithCoordinate:(CLLocationCoordinate2D)aCoordinate
				altitude:(CLLocationDistance)aAltitude
	  horizontalAccuracy:(CLLocationAccuracy)aHAccuracy
		verticalAccuracy:(CLLocationAccuracy)aVAccuracy
				  course:(CLLocationDirection)aCourse
				   speed:(CLLocationSpeed)aSpeed
			   timestamp:(NSDate*)aTimestamp
{
	if ( (self = [super initWithCoordinate:aCoordinate
								  altitude:aAltitude
						horizontalAccuracy:aHAccuracy
						  verticalAccuracy:aVAccuracy
								 timestamp:aTimestamp]) )
	{
		self.speed = aSpeed;
		self.course = aCourse;
		self.timestamp = aTimestamp;
	}
	
	return self;
}


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

#endif


// -----------------------------------------------------------------------------
// APLocation::setTimestamp:
// -----------------------------------------------------------------------------
- (void)setTimestamp:(NSDate*)aTimestamp
{
	if ( apTimestamp != aTimestamp )
	{
		[apTimestamp release];
		apTimestamp = [aTimestamp retain];
	}
}


// -----------------------------------------------------------------------------
// APLocation::dealloc
// -----------------------------------------------------------------------------
- (void)dealloc
{
	self.timestamp = nil;
	[super dealloc];
}


@end
