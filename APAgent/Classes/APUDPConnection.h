//
//  APUDPConnection.h
//  APAgent
//
//  Created by Lvsti on 2010.09.14..
//

#import <Foundation/Foundation.h>
#import <netinet/in.h>


@interface APUDPConnection : NSObject 
{
	int hostSocket;
	struct sockaddr_in address;
}

- (void)setAddress:(NSString*)aAddress;
- (void)setPort:(unsigned short)aPort;

- (void)sendData:(NSData*)aData;

@end
