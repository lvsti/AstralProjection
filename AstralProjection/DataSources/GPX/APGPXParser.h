//
//  APGPXParser.h
//  AstralProjection
//
//  Created by Lvsti on 2010.09.11..
//

#import <Foundation/Foundation.h>


extern NSString* const kGPXPointLatitude;
extern NSString* const kGPXPointLongitude;
extern NSString* const kGPXPointAltitude;
extern NSString* const kGPXPointTime;


typedef enum
{
	kGPXParsingLevelDocument,
	kGPXParsingLevelBody,
	kGPXParsingLevelRoute,
	kGPXParsingLevelTrack,
	kGPXParsingLevelTrackSegment	
} GPXParsingLevel;

typedef enum
{
	kGPXPointParsingLevelNone,
	kGPXPointParsingLevelBase,
	kGPXPointParsingLevelTime,
	kGPXPointParsingLevelElevation
} GPXPointParsingLevel;



@interface APGPXParser : NSObject <NSXMLParserDelegate>
{
	/// accumulator of the character (=non-element) data within an element
	NSMutableString* outstandingCharacters;

	NSMutableDictionary* outstandingPoint;
	
	/// current levels of parsing
	GPXParsingLevel parsingLevel;	
	GPXPointParsingLevel pointParsingLevel;
	
	NSMutableArray* waypoints;
	NSMutableArray* routes;
	NSMutableArray* tracks;
}

@property (nonatomic, retain, readonly) NSArray* waypoints;
@property (nonatomic, retain, readonly) NSArray* routes;
@property (nonatomic, retain, readonly) NSArray* tracks;


- (id)initWithURL:(NSURL*)aUrl;

@end
