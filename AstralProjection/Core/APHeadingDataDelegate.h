//
//  APHeadingDataDelegate.h
//  AstralProjection
//
//  Created by Lkxf on 2010.10.10..
//

#import <Foundation/Foundation.h>
#import "APHeading.h"


@protocol APHeadingDataSource;


@protocol APHeadingDataDelegate <NSObject>

- (void)headingDataSource:(id<APHeadingDataSource>)aDataSource
	   didUpdateToHeading:(APHeading*)aNewHeading;

@end
