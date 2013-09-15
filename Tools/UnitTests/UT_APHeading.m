//
//  UT_APHeading.m
//  APMobileHost
//
//  Created by Tamas Lustyik on 2013.09.13..
//  Copyright (c) 2013 LKXF Studios. All rights reserved.
//

#import "UT_APHeading.h"
#import "APHeading.h"


extern NSString* const kAPHeadingDescriptionFormat;


@interface UT_APHeading ()
{
	NSDate* referenceDate;
}

@end


@implementation UT_APHeading

#if TARGET_OS_IPHONE || __MAC_OS_X_VERSION_MAX_ALLOWED > __MAC_10_6

- (void)setUp
{
    [super setUp];
	
	NSDateComponents* comps = [[NSDateComponents alloc] init];
	[comps setSecond:1];
	[comps setMinute:2];
	[comps setHour:3];
	[comps setDay:4];
	[comps setMonth:5];
	[comps setYear:2006];
	
	referenceDate = [[[NSCalendar currentCalendar] dateFromComponents:comps] retain];
	[comps release];	
}


- (void)tearDown
{
	[referenceDate release];
	
    [super tearDown];
}


- (void)testPublicInterface
{
	STAssertTrue([APHeading conformsToProtocol:@protocol(NSCopying)], @"APHeading doesn't implement <NSCopying>");
	STAssertTrue([APHeading conformsToProtocol:@protocol(NSCoding)], @"APHeading doesn't implement <NSCoding>");
	
	NSArray* publicInterface = @[@"magneticHeading",
							     @"trueHeading",
							     @"headingAccuracy",
							     @"x",
							     @"y",
							     @"z",
							     @"timestamp",
							     @"description"];
	
	for ( NSString* method in publicInterface )
	{
		STAssertTrue([APHeading instancesRespondToSelector:NSSelectorFromString(method)], @"-[APHeading %@] method missing", method);
	}
}


- (void)testObjectConstruction
{
	APHeading* heading = [[APHeading alloc] initWithMagneticHeading:12.1
														trueHeading:34.1
														   accuracy:56.1
																  x:78.1
																  y:90.1
																  z:12.1
														  timestamp:referenceDate];
	
	STAssertEquals(heading.magneticHeading, 12.1, @"magneticHeading property value mismatch");
	STAssertEquals(heading.trueHeading, 34.1, @"trueHeading property value mismatch");
	STAssertEquals(heading.headingAccuracy, 56.1, @"headingAccuracy property value mismatch");
	STAssertEquals(heading.x, 78.1, @"x property value mismatch");
	STAssertEquals(heading.y, 90.1, @"y property value mismatch");
	STAssertEquals(heading.z, 12.1, @"z property value mismatch");
	STAssertEqualObjects(heading.timestamp, referenceDate, @"timestamp property value mismatch");
	
	[heading release];
}


#endif

@end

