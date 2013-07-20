//
//  APHeadingDataDelegate.h
//  AstralProjection
//
//  Created by Lkxf on 2010.10.10..
//

#import <Foundation/Foundation.h>

@class CLHeading;
@protocol APHeadingDataSource;


@protocol APHeadingDataDelegate <NSObject>

- (void)headingDataSource:(id<APHeadingDataSource>)aDataSource
	   didUpdateToHeading:(CLHeading*)aNewHeading;

@end
