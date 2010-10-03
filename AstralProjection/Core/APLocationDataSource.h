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

/**
 * Kicks off the location data source.
 */
- (void)start;

/**
 * Stops the location data source.
 * After returning from this method, the data source MUST NOT generate and pass
 * any more events to its delegate.
 */
- (void)stop;

@end
