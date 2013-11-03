//
//  APAgentDataSource.m
//  AstralProjection
//
//  Created by Lkxf on 2010.09.13..
//

#import "APAgentDataSource.h"

#import <CoreLocation/CoreLocation.h>
#include <sys/socket.h>
#include <unistd.h>
#include <netinet/in.h>

#import "APLocationDataDelegate.h"
#import "APHeadingDataDelegate.h"
#import "APLocation.h"
#import "APHeading.h"


static NSString* const kDateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";

static const NSUInteger kMaxPacketSize = 4096;

static const NSInteger kThreadExecuting = 0;
static const NSInteger kThreadStopping = 1;
static const NSInteger kThreadStopped = 2;



@interface APAgentDataSource ()
{
	id<APLocationDataDelegate> locationDataDelegate;
	id<APHeadingDataDelegate> headingDataDelegate;
	int scoutSocket;
	NSConditionLock* threadLock;
	NSDateFormatter* dateFmt;
	
	BOOL isLocationActive;
	BOOL isHeadingActive;
}

- (void)receiverThread;
- (void)processLocationUpdateMessage:(NSDictionary*)aMessage;
- (void)processLocationErrorMessage:(NSDictionary*)aMessage;
- (void)processHeadingUpdateMessage:(NSDictionary*)aMessage;
@end



@implementation APAgentDataSource

@synthesize locationDataDelegate;
@synthesize headingDataDelegate;


// -----------------------------------------------------------------------------
// APAgentDataSource::initWithUdpPort:
// -----------------------------------------------------------------------------
- (id)initWithUdpPort:(unsigned short)aPort
{
	if ( (self = [super init]) )
	{
		threadLock = [[NSConditionLock alloc] initWithCondition:kThreadStopped];
		
		scoutSocket = socket(PF_INET, SOCK_DGRAM, 0);
		if ( scoutSocket < 0 )
		{
			NSLog(@"ERROR: socket");
		}
		
		struct sockaddr_in address;
		socklen_t slen = sizeof(address);
		
		bzero(&address, slen);
		address.sin_family = AF_INET;
		address.sin_port = htons(aPort);
		address.sin_addr.s_addr = htonl(INADDR_ANY);
		
		if ( bind(scoutSocket, (const struct sockaddr*)&address, slen) < 0 )
		{
			NSLog(@"ERROR: bind");
		}
		
		dateFmt = [[NSDateFormatter alloc] init];
		[dateFmt setDateFormat:kDateFormat];
	}
	
	return self;
}


// -----------------------------------------------------------------------------
// APAgentDataSource::dealloc
// -----------------------------------------------------------------------------
- (void)dealloc
{
	[threadLock lock];
	if ( [threadLock condition] == kThreadExecuting )
	{
		[threadLock unlockWithCondition:kThreadStopping];
	}
	else
	{
		[threadLock unlock];
	}
	
	[threadLock lockWhenCondition:kThreadStopped];
	[threadLock unlock];
	
	[threadLock release];
	
	shutdown(scoutSocket, SHUT_RDWR);
	close(scoutSocket);
	
	[threadLock release];
	[dateFmt release];
	
	[super dealloc];
}


#pragma mark -
#pragma mark from APLocationDataSource:


// -----------------------------------------------------------------------------
// APAgentDataSource::startGeneratingLocationEvents
// -----------------------------------------------------------------------------
- (void)startGeneratingLocationEvents
{
	[threadLock lock];
	if ( [threadLock condition] == kThreadStopped )
	{
		[NSThread detachNewThreadSelector:@selector(receiverThread)
								 toTarget:self
							   withObject:nil];
		
		[threadLock unlockWithCondition:kThreadExecuting];
	}
	else
	{
		[threadLock unlock];
	}

	isLocationActive = YES;
}


// -----------------------------------------------------------------------------
// APAgentDataSource::stopGeneratingLocationEvents
// -----------------------------------------------------------------------------
- (void)stopGeneratingLocationEvents
{
	[threadLock lock];
	if ( [threadLock condition] == kThreadExecuting && !isHeadingActive )
	{
		[threadLock unlockWithCondition:kThreadStopping];
	}
	else
	{
		[threadLock unlock];
	}

	isLocationActive = NO;
}


#pragma mark -
#pragma mark from APHeadingDataSource:


// -----------------------------------------------------------------------------
// APAgentDataSource::startGeneratingHeadingEvents
// -----------------------------------------------------------------------------
- (void)startGeneratingHeadingEvents
{
	[threadLock lock];
	if ( [threadLock condition] == kThreadStopped )
	{
		[NSThread detachNewThreadSelector:@selector(receiverThread)
								 toTarget:self
							   withObject:nil];
		
		[threadLock unlockWithCondition:kThreadExecuting];
	}
	else
	{
		[threadLock unlock];
	}

	isHeadingActive = YES;
}


// -----------------------------------------------------------------------------
// APAgentDataSource::stopGeneratingHeadingEvents
// -----------------------------------------------------------------------------
- (void)stopGeneratingHeadingEvents
{
	[threadLock lock];
	if ( [threadLock condition] == kThreadExecuting && !isLocationActive )
	{
		[threadLock unlockWithCondition:kThreadStopping];
	}
	else
	{
		[threadLock unlock];
	}
	
	isHeadingActive = NO;
}


#pragma mark -
#pragma mark new methods:


// -----------------------------------------------------------------------------
// APAgentDataSource::receiverThread
// -----------------------------------------------------------------------------
- (void)receiverThread
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSMutableData* buffer = [[NSMutableData alloc] initWithLength:kMaxPacketSize+1];
	
	[threadLock lockWhenCondition:kThreadExecuting];
	[threadLock unlock];

	[threadLock lock];
	while ( [threadLock condition] != kThreadStopping )
	{
		[threadLock unlock];
		
		fd_set fds;
		FD_ZERO(&fds);
		FD_SET(scoutSocket, &fds);

		struct timeval tv;
		tv.tv_sec = 0;
		tv.tv_usec = 100*1000;
		
		select(scoutSocket+1, &fds, NULL, NULL, &tv);
		
		if ( FD_ISSET(scoutSocket, &fds) )
		{
			NSAutoreleasePool* iterationPool = [[NSAutoreleasePool alloc] init];

			struct sockaddr_in remoteAddress;
			socklen_t slen = sizeof(remoteAddress);
			
			ssize_t bytesReceived = recvfrom(scoutSocket, 
											 [buffer mutableBytes], 
											 kMaxPacketSize, 
											 0, 
											 (struct sockaddr*)&remoteAddress, 
											 &slen);
			if ( bytesReceived < 0 )
			{
				NSLog(@"ERROR: recvfrom");
			}
			else
			{
				[buffer resetBytesInRange:NSMakeRange(bytesReceived, 1)];
				NSData* packet = [NSData dataWithBytesNoCopy:[buffer mutableBytes]
													  length:bytesReceived
												freeWhenDone:NO];
				NSDictionary* message = [NSJSONSerialization JSONObjectWithData:packet
																		options:0
																		  error:NULL];
				
				NSLog(@"%@",message);
				
				if ( isLocationActive && locationDataDelegate )
				{
					if ( [[message objectForKey:@"type"] isEqualToString:@"update.location"] )
					{
						[self processLocationUpdateMessage:[message objectForKey:@"data"]];
					}
					else if ( [[message objectForKey:@"type"] isEqualToString:@"error"] )
					{
						[self processLocationErrorMessage:[message objectForKey:@"data"]];
					}
				}

				if ( isHeadingActive && headingDataDelegate && 
					 [[message objectForKey:@"type"] isEqualToString:@"update.heading"] )
				{
					[self processHeadingUpdateMessage:[message objectForKey:@"data"]];
				}
			}

			[iterationPool release];
		}
		
		[threadLock lock];
	}
	[threadLock unlock];
	
	// put cleanup here
	[buffer release];
	
	[threadLock lock];
	[threadLock unlockWithCondition:kThreadStopped];
	
	[pool release];
}


// -----------------------------------------------------------------------------
// APAgentDataSource::processLocationUpdateMessage:
// -----------------------------------------------------------------------------
- (void)processLocationUpdateMessage:(NSDictionary*)aMessage
{
	CLLocationCoordinate2D coord;
	
	NSDictionary* oldLoc = [aMessage objectForKey:@"old"];
	coord = CLLocationCoordinate2DMake([[oldLoc objectForKey:@"lat"] doubleValue],
									   [[oldLoc objectForKey:@"lon"] doubleValue]);
	
	
#if TARGET_OS_IPHONE || __MAC_OS_X_VERSION_MIN_REQUIRED > __MAC_10_6
	APLocation* oldLocation = [[APLocation alloc] initWithCoordinate:coord
															altitude:[[oldLoc objectForKey:@"alt"] doubleValue]
												  horizontalAccuracy:[[oldLoc objectForKey:@"hacc"] doubleValue]
													verticalAccuracy:[[oldLoc objectForKey:@"vacc"] doubleValue]
															  course:[[oldLoc objectForKey:@"crs"] doubleValue]
															   speed:[[oldLoc objectForKey:@"spd"] doubleValue]
														   timestamp:[dateFmt dateFromString:[oldLoc objectForKey:@"time"]]];
#else
	APLocation* oldLocation = [[APLocation alloc] initWithCoordinate:coord
															altitude:[[oldLoc objectForKey:@"alt"] doubleValue]
												  horizontalAccuracy:[[oldLoc objectForKey:@"hacc"] doubleValue]
													verticalAccuracy:[[oldLoc objectForKey:@"vacc"] doubleValue]
														   timestamp:[dateFmt dateFromString:[oldLoc objectForKey:@"time"]]];
#endif
	
	NSDictionary* newLoc = [aMessage objectForKey:@"new"];
	coord = CLLocationCoordinate2DMake([[newLoc objectForKey:@"lat"] doubleValue],
									   [[newLoc objectForKey:@"lon"] doubleValue]);

#if TARGET_OS_IPHONE || __MAC_OS_X_VERSION_MIN_REQUIRED > __MAC_10_6
	APLocation* newLocation = [[APLocation alloc] initWithCoordinate:coord
															altitude:[[newLoc objectForKey:@"alt"] doubleValue]
												  horizontalAccuracy:[[newLoc objectForKey:@"hacc"] doubleValue]
													verticalAccuracy:[[newLoc objectForKey:@"vacc"] doubleValue]
															  course:[[newLoc objectForKey:@"crs"] doubleValue]
															   speed:[[newLoc objectForKey:@"spd"] doubleValue]
														   timestamp:[dateFmt dateFromString:[newLoc objectForKey:@"time"]]];
#else
	APLocation* newLocation = [[APLocation alloc] initWithCoordinate:coord
															altitude:[[newLoc objectForKey:@"alt"] doubleValue]
												  horizontalAccuracy:[[newLoc objectForKey:@"hacc"] doubleValue]
													verticalAccuracy:[[newLoc objectForKey:@"vacc"] doubleValue]
														   timestamp:[dateFmt dateFromString:[newLoc objectForKey:@"time"]]];
#endif
	
	[locationDataDelegate locationDataSource:self
						 didUpdateToLocation:newLocation
								fromLocation:oldLocation];
	
	[oldLocation release];
	[newLocation release];
}


// -----------------------------------------------------------------------------
// APAgentDataSource::processLocationErrorMessage:
// -----------------------------------------------------------------------------
- (void)processLocationErrorMessage:(NSDictionary*)aMessage
{
	NSError* error = [NSError errorWithDomain:[aMessage objectForKey:@"domain"]
										 code:[[aMessage objectForKey:@"code"] integerValue]
									 userInfo:[aMessage objectForKey:@"userInfo"]];
	
	[locationDataDelegate locationDataSource:self
			didFailToUpdateLocationWithError:error];
}


// -----------------------------------------------------------------------------
// APAgentDataSource::processHeadingUpdateMessage:
// -----------------------------------------------------------------------------
- (void)processHeadingUpdateMessage:(NSDictionary*)aMessage
{
	APHeading* heading = [[APHeading alloc] initWithMagneticHeading:[[aMessage objectForKey:@"mag"] doubleValue]
														trueHeading:[[aMessage objectForKey:@"true"] doubleValue]
														   accuracy:[[aMessage objectForKey:@"acc"] doubleValue]
																  x:[[aMessage objectForKey:@"x"] doubleValue]
																  y:[[aMessage objectForKey:@"y"] doubleValue]
																  z:[[aMessage objectForKey:@"z"] doubleValue]
														  timestamp:[dateFmt dateFromString:[aMessage objectForKey:@"time"]]];
	
	[headingDataDelegate headingDataSource:self
						didUpdateToHeading:heading];
	
	[heading release];
}




@end
