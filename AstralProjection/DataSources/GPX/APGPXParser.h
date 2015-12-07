//
//  APGPXParser.h
//  AstralProjection
//
//  Created by Lkxf on 2010.09.11..
//

#import <Foundation/Foundation.h>


extern NSString* const kGPXPointLatitude;
extern NSString* const kGPXPointLongitude;
extern NSString* const kGPXPointAltitude;
extern NSString* const kGPXPointTime;


@interface APGPXParser : NSObject

@property (nonatomic, copy, readonly) NSArray* waypoints;
@property (nonatomic, copy, readonly) NSArray* routes;
@property (nonatomic, copy, readonly) NSArray* tracks;

- (instancetype)initWithContentsOfURL:(NSURL*)aURL;

@end
