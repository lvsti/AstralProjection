//
//  APHeadingDataSource.h
//  AstralProjection
//
//  Created by Lvsti on 2010.10.10..
//

#import <Foundation/Foundation.h>


@protocol APHeadingDataDelegate;


@protocol APHeadingDataSource

@property (nonatomic, assign) id<APHeadingDataDelegate> headingDelegate;

/**
 * Kicks off the heading data source.
 */
- (void)startGeneratingHeadingEvents;

/**
 * Stops the heading data source.
 * After returning from this method, the data source MUST NOT generate and pass
 * any more events to its delegate.
 */
- (void)stopGeneratingHeadingEvents;

@end
