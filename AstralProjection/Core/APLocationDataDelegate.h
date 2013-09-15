//
//  APLocationDataDelegate.h
//  AstralProjection
//
//  Created by Lkxf on 2010.09.13..
//

#import <Foundation/Foundation.h>
#import "APLocation.h"


@protocol APLocationDataSource;


@protocol APLocationDataDelegate <NSObject>

- (void)locationDataSource:(id<APLocationDataSource>)aDataSource
	   didUpdateToLocation:(APLocation*)aNewLocation
			  fromLocation:(APLocation*)aOldLocation;

- (void)locationDataSource:(id<APLocationDataSource>)aDataSource
	didFailToUpdateLocationWithError:(NSError*)aError;

@end
