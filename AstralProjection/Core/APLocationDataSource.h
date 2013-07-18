//
//  APLocationDataSource.h
//  AstralProjection
//
//  Created by Lkxf on 2010.09.11..
//

#import <Foundation/Foundation.h>


@protocol APLocationDataDelegate;


@protocol APLocationDataSource <NSObject>

@property (nonatomic, assign) id<APLocationDataDelegate> locationDataDelegate;

/**
 * Kicks off the location data source.
 */
- (void)startGeneratingLocationEvents;

/**
 * Stops the location data source.
 * After returning from this method, the data source MUST NOT generate and pass
 * any more events to its delegate.
 */
- (void)stopGeneratingLocationEvents;

@end
