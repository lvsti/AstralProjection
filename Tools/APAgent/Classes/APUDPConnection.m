//
//  APUDPConnection.m
//  APAgent
//
//  Created by Lvsti on 2010.09.14..
//

#import "APUDPConnection.h"
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>
#import <netinet/in.h>


@implementation APUDPConnection {
    int _hostSocket;
    struct sockaddr_in _address;
}

- (id)init
{
    self = [super init];
	if (self)
	{
		bzero(&_address, sizeof(_address));
		_address.sin_family = AF_INET;

		_hostSocket = socket(PF_INET, SOCK_DGRAM, 0);
		if (_hostSocket < 0)
		{
			NSLog(@"ERROR: socket");
			self = nil;
		}
	}
	
	return self;
}


- (void)dealloc
{
	shutdown(_hostSocket, SHUT_RDWR);
	close(_hostSocket);
}


- (void)setIpAddress:(NSString*)aAddress
{
	_address.sin_addr.s_addr = inet_addr(aAddress.UTF8String);
}


- (void)setPort:(unsigned short)aPort
{
	_address.sin_port = htons(aPort);
}


- (void)sendData:(NSData*)aData
{
	if (sendto(_hostSocket, aData.bytes, aData.length, 0, (const struct sockaddr*)&_address, sizeof(_address)) < 0)
	{
		NSLog(@"ERROR: sendto");
	}
}

@end
