//
//  APGPXDataSource.h
//  AstralProjection
//
//  Created by Lvsti on 2010.09.13..
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
{
	NSArray* waypoints;
	NSArray* routes;
	NSArray* tracks;

	APGPXDataSet activeDataSet;
	NSUInteger activeSubsetIndex;

	double timeScale;
	NSTimeInterval eventFrequency;
	NSConditionLock* threadLock;
	
	id<APLocationDataDelegate> delegate;
}

@property (nonatomic, assign) double timeScale;
@property (nonatomic, assign) NSTimeInterval eventFrequency;
@property (nonatomic, assign) id<APLocationDataDelegate> delegate;

- (id)initWithURL:(NSURL*)aUrl;

- (NSUInteger)cardinalityForDataSet:(APGPXDataSet)aDataSet;
- (void)setActiveDataSet:(APGPXDataSet)aDataSet subsetIndex:(NSUInteger)aIndex;

@end