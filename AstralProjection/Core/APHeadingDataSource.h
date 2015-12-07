//
//  APHeadingDataSource.h
//  AstralProjection
//
//  Created by Lkxf on 2010.10.10..
//

#import <Foundation/Foundation.h>


@protocol APHeadingDataDelegate;


@protocol APHeadingDataSource <NSObject>

@property (nonatomic, weak) id<APHeadingDataDelegate> headingDataDelegate;

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
