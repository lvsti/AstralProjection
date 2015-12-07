//
//  APGPXDataSource.h
//  AstralProjection
//
//  Created by Lkxf on 2010.09.13..
//

#import <Foundation/Foundation.h>
#import "APLocationDataSource.h"


typedef NS_ENUM(NSUInteger, APGPXDataSet)
{
	kAPGPXDataSetWaypoint,
	kAPGPXDataSetRoute,
	kAPGPXDataSetTrack
};


@interface APGPXDataSource : NSObject <APLocationDataSource>

@property (nonatomic, assign) double timeScale;
@property (nonatomic, assign) NSTimeInterval eventFrequency;
@property (nonatomic, weak) id<APLocationDataDelegate> locationDataDelegate;
@property (nonatomic, assign) BOOL autorepeat;

- (id)initWithContentsOfURL:(NSURL*)aURL;

- (NSUInteger)cardinalityForDataSet:(APGPXDataSet)aDataSet;
- (void)setActiveDataSet:(APGPXDataSet)aDataSet subsetIndex:(NSUInteger)aIndex;

@end
