//
//  APAgentDataSource.h
//  AstralProjection
//
//  Created by Lkxf on 2010.09.13..
//

#import <Foundation/Foundation.h>
#import "APLocationDataSource.h"
#import "APHeadingDataSource.h"


@interface APAgentDataSource : NSObject <APLocationDataSource, APHeadingDataSource>

@property (nonatomic, assign) id<APLocationDataDelegate> locationDataDelegate;
@property (nonatomic, assign) id<APHeadingDataDelegate> headingDataDelegate;

- (id)initWithUdpPort:(unsigned short)aPort;

@end
