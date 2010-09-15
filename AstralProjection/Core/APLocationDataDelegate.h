//
//  APLocationDataDelegate.h
//  AstralProjection
//
//  Created by Lvsti on 2010.09.13..
//

#import <Foundation/Foundation.h>


@protocol APLocationDataDelegate <NSObject>

- (void)didUpdateToLocation:(CLLocation*)aNewLocation fromLocation:(CLLocation*)aOldLocation;
- (void)didFailToUpdateLocationWithError:(NSError*)aError;

@end
