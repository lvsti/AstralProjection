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


@interface APGPXParser : NSObject <NSXMLParserDelegate>

@property (nonatomic, retain, readonly) NSArray* waypoints;
@property (nonatomic, retain, readonly) NSArray* routes;
@property (nonatomic, retain, readonly) NSArray* tracks;


- (id)initWithURL:(NSURL*)aUrl;

@end
