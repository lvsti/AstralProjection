//
//  APAgentDataSource.h
//  AstralProjection
//
//  Created by Lvsti on 2010.09.13..
//

#import <Foundation/Foundation.h>
#import "APLocationDataSource.h"
#import "APHeadingDataSource.h"


@interface APAgentDataSource : NSObject <APLocationDataSource, APHeadingDataSource>
{
	id<APLocationDataDelegate> locationDataDelegate;
	id<APHeadingDataDelegate> headingDataDelegate;
	int scoutSocket;
	NSConditionLock* threadLock;
	NSDateFormatter* dateFmt;
	
	BOOL isLocationActive;
	BOOL isHeadingActive;
}

@property (nonatomic, assign) id<APLocationDataDelegate> locationDataDelegate;
@property (nonatomic, assign) id<APHeadingDataDelegate> headingDataDelegate;

@end
