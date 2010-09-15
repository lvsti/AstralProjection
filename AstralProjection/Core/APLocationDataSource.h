//
//  APLocationDataSource.h
//  AstralProjection
//
//  Created by Lvsti on 2010.09.11..
//

#import <Foundation/Foundation.h>


@protocol APLocationDataDelegate;


@protocol APLocationDataSource

@property (nonatomic, assign) id<APLocationDataDelegate> delegate;

- (void)start;
- (void)stop;

@end
