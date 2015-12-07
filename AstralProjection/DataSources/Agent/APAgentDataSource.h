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

@property (nonatomic, weak) id<APLocationDataDelegate> locationDataDelegate;
@property (nonatomic, weak) id<APHeadingDataDelegate> headingDataDelegate;

- (id)initWithUDPPort:(unsigned short)aPort;

@end
