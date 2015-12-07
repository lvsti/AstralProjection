//
//  APUDPConnection.h
//  APAgent
//
//  Created by Lvsti on 2010.09.14..
//

#import <Foundation/Foundation.h>


@interface APUDPConnection : NSObject 

@property (nonatomic, copy) NSString* ipAddress;
@property (nonatomic, assign) unsigned short port;

- (void)sendData:(NSData*)aData;

@end
