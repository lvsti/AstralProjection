//
//  APLocationDataDelegate.h
//  AstralProjection
//
//  Created by Lkxf on 2010.09.13..
//

#import <Foundation/Foundation.h>

@class CLLocation;
@protocol APLocationDataSource;


@protocol APLocationDataDelegate <NSObject>

- (void)locationDataSource:(id<APLocationDataSource>)aDataSource
	   didUpdateToLocation:(CLLocation*)aNewLocation
			  fromLocation:(CLLocation*)aOldLocation;

- (void)locationDataSource:(id<APLocationDataSource>)aDataSource
	didFailToUpdateLocationWithError:(NSError*)aError;

@end
