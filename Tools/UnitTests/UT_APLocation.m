//
//  UT_APLocation.m
//  UnitTests
//
//  Created by Tamas Lustyik on 2013.09.13..
//  Copyright (c) 2013 LKXF Studios. All rights reserved.
//

#import "UT_APLocation.h"
#import "APLocation.h"


@interface UT_APLocation ()
{
	NSDate* referenceDate;
	CLLocation* referenceLocation;
}

@end


@implementation UT_APLocation


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
	
#if TARGET_OS_IPHONE || __MAC_OS_X_VERSION_MIN_REQUIRED > __MAC_10_6
	referenceLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(12.1, 34.1)
													  altitude:56.1
											horizontalAccuracy:78.1
											  verticalAccuracy:90.1
														course:12.1
														 speed:34.1
													 timestamp:referenceDate];
#else
	referenceLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(12.1, 34.1)
													  altitude:56.1
											horizontalAccuracy:78.1
											  verticalAccuracy:90.1
													 timestamp:referenceDate];
#endif
}


- (void)tearDown
{
	[referenceDate release];
	[referenceLocation release];
	
    [super tearDown];
}


- (void)testPublicInterface
{
	STAssertTrue([APLocation conformsToProtocol:@protocol(NSCopying)], @"APLocation doesn't implement <NSCopying>");
	STAssertTrue([APLocation conformsToProtocol:@protocol(NSCoding)], @"APLocation doesn't implement <NSCoding>");
	
	NSArray* publicInterface = @[@"coordinate",
							  @"altitude",
							  @"horizontalAccuracy",
							  @"verticalAccuracy",
							  @"timestamp",
#if TARGET_OS_IPHONE || __MAC_OS_X_VERSION_MIN_REQUIRED > __MAC_10_6
							  @"course",
							  @"speed",
#endif
							  @"description",
							  @"getDistanceFrom:",
							  @"distanceFromLocation:"];
	
	for ( NSString* method in publicInterface )
	{
		STAssertTrue([APLocation instancesRespondToSelector:NSSelectorFromString(method)], @"-[APLocation %@] method missing", method);
	}
}


- (void)testObjectConstruction
{
#if TARGET_OS_IPHONE || __MAC_OS_X_VERSION_MIN_REQUIRED > __MAC_10_6
	APLocation* location = [[APLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(12.1, 34.1)
														 altitude:56.1
											   horizontalAccuracy:78.1
												 verticalAccuracy:90.1
														   course:12.1
															speed:34.1
														timestamp:referenceDate];
#else
	APLocation* location = [[APLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(12.1, 34.1)
														 altitude:56.1
											   horizontalAccuracy:78.1
												 verticalAccuracy:90.1
														timestamp:referenceDate];
#endif
	
	STAssertEquals(location.coordinate.latitude, 12.1, @"coordinate.latitude property value mismatch");
	STAssertEquals(location.coordinate.longitude, 34.1, @"coordinate.longitude property value mismatch");
	STAssertEquals(location.altitude, 56.1, @"altitude property value mismatch");
	STAssertEquals(location.horizontalAccuracy, 78.1, @"horizontalAccuracy property value mismatch");
	STAssertEquals(location.verticalAccuracy, 90.1, @"verticalAccuracy property value mismatch");
	STAssertEqualObjects(location.timestamp, referenceDate, @"timestamp property value mismatch");
	
#if TARGET_OS_IPHONE || __MAC_OS_X_VERSION_MIN_REQUIRED > __MAC_10_6
	STAssertEquals(location.course, 12.1, @"course property value mismatch");
	STAssertEquals(location.speed, 34.1, @"speed property value mismatch");
#endif
}


- (void)testSemanticEquality
{
#if TARGET_OS_IPHONE || __MAC_OS_X_VERSION_MIN_REQUIRED > __MAC_10_6
	APLocation* location = [[APLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(12.1, 34.1)
														 altitude:56.1
											   horizontalAccuracy:78.1
												 verticalAccuracy:90.1
														   course:12.1
															speed:34.1
														timestamp:referenceDate];
#else
	APLocation* location = [[APLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(12.1, 34.1)
														 altitude:56.1
											   horizontalAccuracy:78.1
												 verticalAccuracy:90.1
														timestamp:referenceDate];
#endif
	
	STAssertEquals(location.coordinate, referenceLocation.coordinate, @"coordinate property value mismatch");
	STAssertEquals(location.altitude, referenceLocation.altitude, @"altitude property value mismatch");
	STAssertEquals(location.horizontalAccuracy, referenceLocation.horizontalAccuracy, @"horizontalAccuracy property value mismatch");
	STAssertEquals(location.verticalAccuracy, referenceLocation.verticalAccuracy, @"verticalAccuracy property value mismatch");
	STAssertEqualObjects(location.timestamp, referenceLocation.timestamp, @"timestamp property value mismatch");

#if TARGET_OS_IPHONE || __MAC_OS_X_VERSION_MIN_REQUIRED > __MAC_10_6
	STAssertEquals(location.course, referenceLocation.course, @"course property value mismatch");
	STAssertEquals(location.speed, referenceLocation.speed, @"speed property value mismatch");
#endif
}


@end


