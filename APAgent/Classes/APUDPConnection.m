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


@implementation APUDPConnection


- (id)init
{
	if ( (self = [super init]) )
	{
		bzero(&address, sizeof(address));
		address.sin_family = AF_INET;

		hostSocket = socket(PF_INET, SOCK_DGRAM, 0);
		if ( hostSocket < 0 )
		{
			NSLog(@"ERROR: socket");
			[self release];
			self = nil;
		}
	}
	
	return self;
}


- (void)dealloc
{
	shutdown(hostSocket, SHUT_RDWR);
	close(hostSocket);
	[super dealloc];
}


- (void)setAddress:(NSString*)aAddress
{
	address.sin_addr.s_addr = inet_addr([aAddress cStringUsingEncoding:NSASCIIStringEncoding]);
}


- (void)setPort:(unsigned short)aPort
{
	address.sin_port = htons(aPort);
}


- (void)sendData:(NSData*)aData
{
	if ( sendto( hostSocket, [aData bytes], [aData length], 0, (const struct sockaddr*)&address, sizeof(address) ) < 0 )
	{
		NSLog(@"ERROR: sendto");
	}
	
}



@end
