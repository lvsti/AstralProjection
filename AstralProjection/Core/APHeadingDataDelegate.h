//
//  APHeadingDataDelegate.h
//  AstralProjection
//
//  Created by Lvsti on 2010.10.10..
//

#import <Foundation/Foundation.h>


@class APHeading;


@protocol APHeadingDataDelegate <NSObject>

- (void)didUpdateToHeading:(APHeading*)aNewHeading;

@end
