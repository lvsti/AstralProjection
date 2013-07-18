//
//  APGPXDataSource.h
//  AstralProjection
//
//  Created by Lkxf on 2010.09.13..
//

#import <Foundation/Foundation.h>
#import "APLocationDataSource.h"


typedef enum
{
	kAPGPXDataSetWaypoint,
	kAPGPXDataSetRoute,
	kAPGPXDataSetTrack
} APGPXDataSet;


@interface APGPXDataSource : NSObject <APLocationDataSource>

@property (nonatomic, assign) double timeScale;
@property (nonatomic, assign) NSTimeInterval eventFrequency;
@property (nonatomic, assign) id<APLocationDataDelegate> locationDataDelegate;
@property (nonatomic, assign) BOOL autorepeat;

- (id)initWithURL:(NSURL*)aUrl;

- (NSUInteger)cardinalityForDataSet:(APGPXDataSet)aDataSet;
- (void)setActiveDataSet:(APGPXDataSet)aDataSet subsetIndex:(NSUInteger)aIndex;

@end
