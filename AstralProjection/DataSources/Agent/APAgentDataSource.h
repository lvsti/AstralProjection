//
//  APAgentDataSource.h
//  AstralProjection
//
//  Created by Lvsti on 2010.09.13..
//

#import <Foundation/Foundation.h>
#import "APLocationDataSource.h"


@interface APAgentDataSource : NSObject <APLocationDataSource>
{
	id<APLocationDataDelegate> delegate;
	int scoutSocket;
	NSConditionLock* threadLock;
}

@property (nonatomic, assign) id<APLocationDataDelegate> delegate;

@end
