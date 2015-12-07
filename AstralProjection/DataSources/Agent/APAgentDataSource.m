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
	int _scoutSocket;
	NSConditionLock* _threadLock;
	NSDateFormatter* _dateFmt;
	
	BOOL _isLocationActive;
	BOOL _isHeadingActive;
}

@end



@implementation APAgentDataSource

- (id)initWithUDPPort:(unsigned short)aPort
{
    self = [super init];
	if (self)
	{
		_threadLock = [[NSConditionLock alloc] initWithCondition:kThreadStopped];
		
		_scoutSocket = socket(PF_INET, SOCK_DGRAM, 0);
		if (_scoutSocket < 0)
		{
			NSLog(@"ERROR: socket");
		}
		
		struct sockaddr_in address;
		socklen_t slen = sizeof(address);
		
		bzero(&address, slen);
		address.sin_family = AF_INET;
		address.sin_port = htons(aPort);
		address.sin_addr.s_addr = htonl(INADDR_ANY);
		
		if (bind(_scoutSocket, (const struct sockaddr*)&address, slen) < 0)
		{
			NSLog(@"ERROR: bind");
		}
		
		_dateFmt = [NSDateFormatter new];
        _dateFmt.dateFormat = kDateFormat;
	}
	
	return self;
}


- (void)dealloc
{
	[_threadLock lock];
	if (_threadLock.condition == kThreadExecuting)
	{
		[_threadLock unlockWithCondition:kThreadStopping];
	}
	else
	{
		[_threadLock unlock];
	}
	
	[_threadLock lockWhenCondition:kThreadStopped];
	[_threadLock unlock];
	
	shutdown(_scoutSocket, SHUT_RDWR);
	close(_scoutSocket);
}


#pragma mark - from APLocationDataSource:


- (void)startGeneratingLocationEvents
{
	[_threadLock lock];
	if (_threadLock.condition == kThreadStopped)
	{
		[NSThread detachNewThreadSelector:@selector(receiverThread)
								 toTarget:self
							   withObject:nil];
		
		[_threadLock unlockWithCondition:kThreadExecuting];
	}
	else
	{
		[_threadLock unlock];
	}

	_isLocationActive = YES;
}


- (void)stopGeneratingLocationEvents
{
	[_threadLock lock];
	if (_threadLock.condition == kThreadExecuting && !_isHeadingActive)
	{
		[_threadLock unlockWithCondition:kThreadStopping];
	}
	else
	{
		[_threadLock unlock];
	}

	_isLocationActive = NO;
}


#pragma mark - from APHeadingDataSource:


- (void)startGeneratingHeadingEvents
{
	[_threadLock lock];
	if (_threadLock.condition == kThreadStopped)
	{
		[NSThread detachNewThreadSelector:@selector(receiverThread)
								 toTarget:self
							   withObject:nil];
		
		[_threadLock unlockWithCondition:kThreadExecuting];
	}
	else
	{
		[_threadLock unlock];
	}

	_isHeadingActive = YES;
}


- (void)stopGeneratingHeadingEvents
{
	[_threadLock lock];
	if (_threadLock.condition == kThreadExecuting && !_isLocationActive)
	{
		[_threadLock unlockWithCondition:kThreadStopping];
	}
	else
	{
		[_threadLock unlock];
	}
	
	_isHeadingActive = NO;
}


#pragma mark - new methods:


- (void)receiverThread
{
    @autoreleasepool {
	NSMutableData* buffer = [[NSMutableData alloc] initWithLength:kMaxPacketSize+1];
	
	[_threadLock lockWhenCondition:kThreadExecuting];
	[_threadLock unlock];

	[_threadLock lock];
	while (_threadLock.condition != kThreadStopping)
	{
		[_threadLock unlock];
		
		fd_set fds;
		FD_ZERO(&fds);
		FD_SET(_scoutSocket, &fds);

		struct timeval tv;
		tv.tv_sec = 0;
		tv.tv_usec = 100*1000;
		
		select(_scoutSocket+1, &fds, NULL, NULL, &tv);
		
		if (FD_ISSET(_scoutSocket, &fds))
		{
            @autoreleasepool {

			struct sockaddr_in remoteAddress;
			socklen_t slen = sizeof(remoteAddress);
			
			ssize_t bytesReceived = recvfrom(_scoutSocket, 
											 [buffer mutableBytes], 
											 kMaxPacketSize, 
											 0, 
											 (struct sockaddr*)&remoteAddress, 
											 &slen);
			if (bytesReceived < 0)
			{
				NSLog(@"ERROR: recvfrom");
			}
			else
			{
				[buffer resetBytesInRange:NSMakeRange(bytesReceived, 1)];
				NSData* packet = [NSData dataWithBytesNoCopy:buffer.mutableBytes
													  length:bytesReceived
												freeWhenDone:NO];
				NSDictionary* message = [NSJSONSerialization JSONObjectWithData:packet
																		options:0
																		  error:NULL];
				
				NSLog(@"%@",message);
				
				if (_isLocationActive && _locationDataDelegate)
				{
					if ([message[@"type"] isEqualToString:@"update.location"])
					{
						[self processLocationUpdateMessage:message[@"data"]];
					}
					else if ([message[@"type"] isEqualToString:@"error"])
					{
						[self processLocationErrorMessage:message[@"data"]];
					}
				}

				if (_isHeadingActive && _headingDataDelegate &&
                    [message[@"type"] isEqualToString:@"update.heading"])
				{
					[self processHeadingUpdateMessage:message[@"data"]];
				}
			}

            }
		}
		
		[_threadLock lock];
	}
	[_threadLock unlock];
	
	// put cleanup here
	[_threadLock lock];
	[_threadLock unlockWithCondition:kThreadStopped];
    }
}


- (void)processLocationUpdateMessage:(NSDictionary*)aMessage
{
	CLLocationCoordinate2D coord;
	
	NSDictionary* oldLoc = aMessage[@"old"];
	coord = CLLocationCoordinate2DMake([oldLoc[@"lat"] doubleValue],
									   [oldLoc[@"lon"] doubleValue]);
	
	
	APLocation* oldLocation = [[APLocation alloc] initWithCoordinate:coord
															altitude:[oldLoc[@"alt"] doubleValue]
												  horizontalAccuracy:[oldLoc[@"hacc"] doubleValue]
													verticalAccuracy:[oldLoc[@"vacc"] doubleValue]
															  course:[oldLoc[@"crs"] doubleValue]
															   speed:[oldLoc[@"spd"] doubleValue]
														   timestamp:[_dateFmt dateFromString:oldLoc[@"time"]]];
	
	NSDictionary* newLoc = aMessage[@"new"];
	coord = CLLocationCoordinate2DMake([newLoc[@"lat"] doubleValue],
									   [newLoc[@"lon"] doubleValue]);

	APLocation* newLocation = [[APLocation alloc] initWithCoordinate:coord
															altitude:[newLoc[@"alt"] doubleValue]
												  horizontalAccuracy:[newLoc[@"hacc"] doubleValue]
													verticalAccuracy:[newLoc[@"vacc"] doubleValue]
															  course:[newLoc[@"crs"] doubleValue]
															   speed:[newLoc[@"spd"] doubleValue]
														   timestamp:[_dateFmt dateFromString:newLoc[@"time"]]];
	
	[_locationDataDelegate locationDataSource:self
                          didUpdateToLocation:newLocation
                                 fromLocation:oldLocation];
}


- (void)processLocationErrorMessage:(NSDictionary*)aMessage
{
	NSError* error = [NSError errorWithDomain:aMessage[@"domain"]
										 code:[aMessage[@"code"] integerValue]
									 userInfo:aMessage[@"userInfo"]];
	
	[_locationDataDelegate locationDataSource:self
             didFailToUpdateLocationWithError:error];
}


- (void)processHeadingUpdateMessage:(NSDictionary*)aMessage
{
	APHeading* heading = [[APHeading alloc] initWithMagneticHeading:[aMessage[@"mag"] doubleValue]
														trueHeading:[aMessage[@"true"] doubleValue]
														   accuracy:[aMessage[@"acc"] doubleValue]
																  x:[aMessage[@"x"] doubleValue]
																  y:[aMessage[@"y"] doubleValue]
																  z:[aMessage[@"z"] doubleValue]
														  timestamp:[_dateFmt dateFromString:aMessage[@"time"]]];
	
	[_headingDataDelegate headingDataSource:self
                         didUpdateToHeading:heading];
}


@end
