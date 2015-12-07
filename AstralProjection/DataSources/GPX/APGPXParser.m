//
//  APGPXParser.m
//  AstralProjection
//
//  Created by Lkxf on 2010.09.11..
//

#import "APGPXParser.h"

// CONSTANTS

NSString* const kGPXPointLatitude = @"lat";
NSString* const kGPXPointLongitude = @"long";
NSString* const kGPXPointAltitude = @"alt";
NSString* const kGPXPointTime = @"time";


/// URI specifying the GPX namespace
static NSString* const kGPX10NamespaceURI = @"http://www.topografix.com/GPX/1/0";
static NSString* const kGPX11NamespaceURI = @"http://www.topografix.com/GPX/1/1";

/// GPX date format (xsd:dateTime)
static NSString* const kGPXDateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";

/// GPX elements and attributes
static NSString* const kGPXElemRoot = @"gpx";
static NSString* const kGPXElemWaypoint = @"wpt";
static NSString* const kGPXAttrPointLatitude = @"lat";
static NSString* const kGPXAttrPointLongitude = @"lon";
static NSString* const kGPXElemPointTime = @"time";
static NSString* const kGPXElemPointElevation = @"ele";

static NSString* const kGPXElemRoute = @"rte";
static NSString* const kGPXElemRoutePoint = @"rtept";

static NSString* const kGPXElemTrack = @"trk";
static NSString* const kGPXElemTrackSegment = @"trkseg";
static NSString* const kGPXElemTrackPoint = @"trkpt";


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



@interface APGPXParser () <NSXMLParserDelegate>
{
	/// accumulator of the character (=non-element) data within an element
	NSMutableString* _outstandingCharacters;
	
	NSMutableDictionary* _outstandingPoint;
	
	/// current levels of parsing
	GPXParsingLevel _parsingLevel;
	GPXPointParsingLevel _pointParsingLevel;
    
    NSMutableArray* _waypoints;
    NSMutableArray* _routes;
    NSMutableArray* _tracks;
}

@end



NSInteger GPXPointSortByTimestampAsc(NSDictionary* aLeft, NSDictionary* aRight, void* aContext)
{
	NSTimeInterval delta = [aLeft[kGPXPointTime] timeIntervalSinceDate:aRight[kGPXPointTime]];
	return (delta < 0)? NSOrderedAscending: ((delta > 0)? NSOrderedDescending: NSOrderedSame);
}


NSInteger GPXTrackSegmentSortByTimestampAsc( id aLeft, id aRight, void* aContext )
{
	NSTimeInterval delta = [[[aLeft objectAtIndex:0] objectForKey:kGPXPointTime] 
							timeIntervalSinceDate:[[aRight objectAtIndex:0] objectForKey:kGPXPointTime]];
	return (delta < 0)? NSOrderedAscending: ((delta > 0)? NSOrderedDescending: NSOrderedSame);
}




@implementation APGPXParser


- (instancetype)initWithContentsOfURL:(NSURL*)aURL
{
    NSParameterAssert(aURL);
    self = [super init];
	if (self)
	{
		_waypoints = [NSMutableArray new];
		_routes = [NSMutableArray new];
		_tracks = [NSMutableArray new];

		[self parseFileAtURL:aURL];
	}
	
	return self;
}


- (void)parseFileAtURL:(NSURL*)aURL
{
	NSXMLParser* parser = [[NSXMLParser alloc] initWithContentsOfURL:aURL];
    parser.delegate = self;
    parser.shouldProcessNamespaces = YES;
    parser.shouldReportNamespacePrefixes = YES;
    parser.shouldResolveExternalEntities = YES;
	
	// initialize variables
	[_waypoints removeAllObjects];
	[_routes removeAllObjects];
	[_tracks removeAllObjects];
	
	_outstandingCharacters = nil;
	_parsingLevel = kGPXParsingLevelDocument;
	_pointParsingLevel = kGPXPointParsingLevelNone;
	
	// perform parsing
	[parser parse];
	
	// check if there has been errors
    NSError* parseError = [parser parserError];
    if (parseError) 
	{
		[_waypoints removeAllObjects];
		[_routes removeAllObjects];
		[_tracks removeAllObjects];
    }
	
	// cleanup, sorting, etc
	[_waypoints sortUsingFunction:GPXPointSortByTimestampAsc context:NULL];
	
	for (NSMutableArray* route in _routes)
	{
		if (route.count == 0)
		{
			// don't add empty routes
			[_routes removeObject:route];
		}
		else
		{
			[route sortUsingFunction:GPXPointSortByTimestampAsc context:NULL];
		}
	}
	
	for (NSMutableArray* track in _tracks)
	{
		for (NSMutableArray* segment in track)
		{
			if (segment.count == 0)
			{
				// don't add empty segments
				[track removeObject:segment];
			}
			else
			{
				[segment sortUsingFunction:GPXPointSortByTimestampAsc context:NULL];
			}
		}
		
		if (track.count == 0)
		{
			// don't add empty tracks
			[_tracks removeObject:track];
		}
		else
		{
			[track sortUsingFunction:GPXTrackSegmentSortByTimestampAsc context:NULL];
		}
	}
}


#pragma mark - from NSXMLParserDelegate:


- (void)parser:(NSXMLParser*)aParser didStartElement:(NSString*)aElementName
  namespaceURI:(NSString*)aNamespaceURI qualifiedName:(NSString*)aQfdName 
	attributes:(NSDictionary*)aAttributes
{
//	printf("<%s>\n",[aQfdName cStringUsingEncoding:NSASCIIStringEncoding]);
	
	BOOL bypassPointParser = NO;
	
	switch (_parsingLevel)
	{
		case kGPXParsingLevelDocument:
		{
			if ([aElementName isEqualToString:kGPXElemRoot])
			{
				if (![aNamespaceURI isEqualToString:kGPX10NamespaceURI] &&
					![aNamespaceURI isEqualToString:kGPX11NamespaceURI])
				{
					// unknown format
					[NSException raise:@"GPXParserException" format:@"unsupported GPX version"];
					return;
				}
				
				// GPX body starts
				_parsingLevel = kGPXParsingLevelBody;
			}
			break;
		}
			
		case kGPXParsingLevelBody:
		{
			if ([aElementName isEqualToString:kGPXElemWaypoint])
			{
				// waypoint starts
				_pointParsingLevel = kGPXPointParsingLevelBase;
				bypassPointParser = YES;
				
                _outstandingPoint = [@{kGPXPointLatitude: aAttributes[kGPXAttrPointLatitude],
                                       kGPXPointLongitude: aAttributes[kGPXAttrPointLongitude]} mutableCopy];
			}
			else if ([aElementName isEqualToString:kGPXElemRoute])
			{
				// route section starts
				_parsingLevel = kGPXParsingLevelRoute;
				
				[_routes addObject:[NSMutableArray array]];
			}
			else if ([aElementName isEqualToString:kGPXElemTrack])
			{
				// track section starts
				_parsingLevel = kGPXParsingLevelTrack;

				[_tracks addObject:[NSMutableArray array]];
			}
			break;
		}

		case kGPXParsingLevelRoute:
		{
			if ([aElementName isEqualToString:kGPXElemRoutePoint])
			{
				// waypoint starts
				_pointParsingLevel = kGPXPointParsingLevelBase;
				bypassPointParser = YES;
				
                _outstandingPoint = [@{kGPXPointLatitude: aAttributes[kGPXAttrPointLatitude],
                                       kGPXPointLongitude: aAttributes[kGPXAttrPointLongitude]} mutableCopy];
			}
			break;
		}
		
		case kGPXParsingLevelTrack:
		{
			if ([aElementName isEqualToString:kGPXElemTrackSegment])
			{
				// track segment starts
				_parsingLevel = kGPXParsingLevelTrackSegment;

				[_tracks.lastObject addObject:[NSMutableArray array]];
			}			
			break;
		}
		
		case kGPXParsingLevelTrackSegment:
		{
			if ([aElementName isEqualToString:kGPXElemTrackPoint])
			{
				// waypoint starts
				_pointParsingLevel = kGPXPointParsingLevelBase;
				bypassPointParser = YES;
				
                _outstandingPoint = [@{kGPXPointLatitude: aAttributes[kGPXAttrPointLatitude],
                                       kGPXPointLongitude: aAttributes[kGPXAttrPointLongitude]} mutableCopy];
			}
			break;
		}
	}

	if (!bypassPointParser)
	{
		switch (_pointParsingLevel)
		{
			case kGPXPointParsingLevelBase:
			{
				if ([aElementName isEqualToString:kGPXElemPointTime])
				{
					_pointParsingLevel = kGPXPointParsingLevelTime;
					
					// prepare to accept character data
					_outstandingCharacters = [NSMutableString new];
				}
				else if ([aElementName isEqualToString:kGPXElemPointElevation])
				{
					_pointParsingLevel = kGPXPointParsingLevelElevation;
					
					// prepare to accept character data
					_outstandingCharacters = [NSMutableString new];
				}				
				break;
			}
				
			default:
			{
				break;
			}
		}
	}
}


- (void)parser:(NSXMLParser*)aParser didEndElement:(NSString*)aElementName
    namespaceURI:(NSString*)aNamespaceURI qualifiedName:(NSString*)aQfdName
{
	BOOL bypassPointParsing = NO;
	
	switch (_parsingLevel)
	{
		case kGPXParsingLevelDocument:
		{
			// don't care
			break;
		}

		case kGPXParsingLevelBody:
		{
			if ([aElementName isEqualToString:kGPXElemRoot])
			{
				_parsingLevel = kGPXParsingLevelDocument;
				bypassPointParsing = YES;
			}
			break;
		}
			
		case kGPXParsingLevelRoute:
		{
			if ([aElementName isEqualToString:kGPXElemRoute])
			{
				_parsingLevel = kGPXParsingLevelBody;
				bypassPointParsing = YES;
			}
			break;
		}
			
		case kGPXParsingLevelTrack:
		{
			if ([aElementName isEqualToString:kGPXElemTrack])
			{
				_parsingLevel = kGPXParsingLevelBody;
				bypassPointParsing = YES;
			}
			break;
		}
			
		case kGPXParsingLevelTrackSegment:
		{
			if ([aElementName isEqualToString:kGPXElemTrackSegment])
			{
				_parsingLevel = kGPXParsingLevelTrack;
				bypassPointParsing = YES;
			}
			break;
		}
	}
	
	if (!bypassPointParsing)
	{
		switch (_pointParsingLevel)
		{
			case kGPXPointParsingLevelBase:
			{
				if (_parsingLevel == kGPXParsingLevelBody &&
                    [aElementName isEqualToString:kGPXElemWaypoint])
				{
					// waypoint closed
					[_waypoints addObject:_outstandingPoint];
					_outstandingPoint = nil;
					
					_pointParsingLevel = kGPXPointParsingLevelNone;
				}
				else if (_parsingLevel == kGPXParsingLevelRoute &&
						 [aElementName isEqualToString:kGPXElemRoutePoint])
				{
					// route point closed
					[_routes.lastObject addObject:_outstandingPoint];
					_outstandingPoint = nil;

					_pointParsingLevel = kGPXPointParsingLevelNone;
				}
				else if (_parsingLevel == kGPXParsingLevelTrackSegment &&
						 [aElementName isEqualToString:kGPXElemTrackPoint])
				{
					// track point closed
					[[_tracks.lastObject lastObject] addObject:_outstandingPoint];
					_outstandingPoint = nil;

					_pointParsingLevel = kGPXPointParsingLevelNone;
				}
				break;
			}
			
			case kGPXPointParsingLevelTime:
			{
				if ([aElementName isEqualToString:kGPXElemPointTime])
				{
					// time tag closed
					_pointParsingLevel = kGPXPointParsingLevelBase;
					
					NSDateFormatter* dateFmt = [NSDateFormatter new];
                    dateFmt.dateFormat = kGPXDateFormat;
					NSDate* pointTime = [dateFmt dateFromString:_outstandingCharacters];
					
                    _outstandingPoint[kGPXPointTime] = pointTime;
					_outstandingCharacters = nil;
				}
				break;
			}

			case kGPXPointParsingLevelElevation:
			{
				if ([aElementName isEqualToString:kGPXElemPointElevation])
				{
					// time tag closed
					_pointParsingLevel = kGPXPointParsingLevelBase;
					
					NSScanner* scanner = [NSScanner scannerWithString:_outstandingCharacters];
					double value = 0;
					[scanner scanDouble:&value];
					
                    _outstandingPoint[kGPXPointAltitude] = @(value);
					_outstandingCharacters = nil;
				}
				break;
			}

			default:
			{
				break;
			}
		}
	}
	
//	printf("</%s>\n",[aQfdName cStringUsingEncoding:NSASCIIStringEncoding]);
}


- (void)parser:(NSXMLParser*)aParser foundCharacters:(NSString*)aString
{
//	printf("\"%s\"\n",[aString cStringUsingEncoding:NSUTF8StringEncoding]);
	
	// simply append the new characters into the accumulation buffer
	[_outstandingCharacters appendString:aString];
}


@end
