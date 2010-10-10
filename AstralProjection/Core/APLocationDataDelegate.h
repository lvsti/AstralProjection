//
//  APLocationDataDelegate.h
//  AstralProjection
//
//  Created by Lvsti on 2010.09.13..
//

#import <Foundation/Foundation.h>

@class APLocation;

@protocol APLocationDataDelegate <NSObject>

- (void)didUpdateToLocation:(APLocation*)aNewLocation fromLocation:(APLocation*)aOldLocation;
- (void)didFailToUpdateLocationWithError:(NSError*)aError;

@end
