//
//  APGPXParser.m
//  AstralProjection
//
//  Created by Lvsti on 2010.09.11..
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


@interface APGPXParser ()

- (void)parseURL:(NSURL*)aUrl;

@end



NSInteger GPXPointSortByTimestampAsc( id aLeft, id aRight, void* aContext )
{
	NSTimeInterval delta = [[aLeft objectForKey:kGPXPointTime]
							timeIntervalSinceDate:[aRight objectForKey:kGPXPointTime]];
	return (delta < 0)? NSOrderedAscending: ((delta > 0)? NSOrderedDescending: NSOrderedSame);
}


NSInteger GPXTrackSegmentSortByTimestampAsc( id aLeft, id aRight, void* aContext )
{
	NSTimeInterval delta = [[[aLeft objectAtIndex:0] objectForKey:kGPXPointTime] 
							timeIntervalSinceDate:[[aRight objectAtIndex:0] objectForKey:kGPXPointTime]];
	return (delta < 0)? NSOrderedAscending: ((delta > 0)? NSOrderedDescending: NSOrderedSame);
}




@implementation APGPXParser

@synthesize waypoints, routes, tracks;


// -----------------------------------------------------------------------------
// APGPXParser::initWithURL:
// -----------------------------------------------------------------------------
- (id)initWithURL:(NSURL*)aUrl
{
	if ( (self = [super init]) )
	{
		waypoints = [[NSMutableArray alloc] init];
		routes = [[NSMutableArray alloc] init];
		tracks = [[NSMutableArray alloc] init];

		[self parseURL:aUrl];
	}
	
	return self;
}


// -----------------------------------------------------------------------------
// APGPXParser::dealloc
// -----------------------------------------------------------------------------
- (void)dealloc
{
	[waypoints release];
	[routes release];
	[tracks release];
	[super dealloc];
}


// -----------------------------------------------------------------------------
// APGPXParser::parseURL:
// -----------------------------------------------------------------------------
- (void)parseURL:(NSURL*)aUrl
{
	NSXMLParser* parser = [[NSXMLParser alloc] initWithContentsOfURL:aUrl];
	[parser setDelegate:self];
	[parser setShouldProcessNamespaces:YES];
	[parser setShouldReportNamespacePrefixes:NO];
	[parser setShouldResolveExternalEntities:NO];
	
	// initialize variables
	[waypoints removeAllObjects];
	[routes removeAllObjects];
	[tracks removeAllObjects];
	
	outstandingCharacters = nil;
	parsingLevel = kGPXParsingLevelDocument;
	pointParsingLevel = kGPXPointParsingLevelNone;
	
	// perform parsing
	[parser parse];
	
	// check if there has been errors
    NSError* parseError = [parser parserError];
    if (parseError) 
	{
		[waypoints removeAllObjects];
		[routes removeAllObjects];
		[tracks removeAllObjects];
    }
	
	[parser release];
	
	// cleanup, sorting, etc
	[waypoints sortUsingFunction:GPXPointSortByTimestampAsc context:NULL];	
	
	for ( NSMutableArray* route in routes )
	{
		if ( ![route count] )
		{
			// don't add empty routes
			[routes removeObject:route];
		}
		else
		{
			[route sortUsingFunction:GPXPointSortByTimestampAsc context:NULL];
		}
	}
	
	for ( NSMutableArray* track in tracks )
	{
		for ( NSMutableArray* segment in track )
		{
			if ( ![segment count] )
			{
				// don't add empty segments
				[track removeObject:segment];
			}
			else
			{
				[segment sortUsingFunction:GPXPointSortByTimestampAsc context:NULL];
			}
		}
		
		if ( ![track count] )
		{
			// don't add empty tracks
			[tracks removeObject:track];
		}
		else
		{
			[track sortUsingFunction:GPXTrackSegmentSortByTimestampAsc context:NULL];
		}

	}
}



#pragma mark -
#pragma mark from NSXMLParserDelegate:


// -----------------------------------------------------------------------------
// APGPXParser::parser:didStartElement:namespaceURI:qualifiedName:attributes:
// -----------------------------------------------------------------------------
- (void)parser:(NSXMLParser*)aParser didStartElement:(NSString*)aElementName 
  namespaceURI:(NSString*)aNamespaceURI qualifiedName:(NSString*)aQfdName 
	attributes:(NSDictionary*)aAttributes
{
//	printf("<%s>\n",[aQfdName cStringUsingEncoding:NSASCIIStringEncoding]);
	
	BOOL bypassPointParser = NO;
	
	switch ( parsingLevel )
	{
		case kGPXParsingLevelDocument:
		{
			if ( [aNamespaceURI isEqualToString:kGPX10NamespaceURI] || 
				 [aNamespaceURI isEqualToString:kGPX11NamespaceURI] &&
				 [aElementName isEqualToString:kGPXElemRoot] )
			{
				// GPX body starts
				parsingLevel = kGPXParsingLevelBody;
			}
			break;
		}
			
		case kGPXParsingLevelBody:
		{
			if ( [aElementName isEqualToString:kGPXElemWaypoint] )
			{
				// waypoint starts
				pointParsingLevel = kGPXPointParsingLevelBase;
				bypassPointParser = YES;
				
				outstandingPoint = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
									[aAttributes objectForKey:kGPXAttrPointLatitude], kGPXPointLatitude,
									[aAttributes objectForKey:kGPXAttrPointLongitude], kGPXPointLongitude,
									nil];
			}
			else if ( [aElementName isEqualToString:kGPXElemRoute] )
			{
				// route section starts
				parsingLevel = kGPXParsingLevelRoute;
				
				[routes addObject:[NSMutableArray array]];
			}
			else if ( [aElementName isEqualToString:kGPXElemTrack] )
			{
				// track section starts
				parsingLevel = kGPXParsingLevelTrack;

				[tracks addObject:[NSMutableArray array]];
			}
			break;
		}

		case kGPXParsingLevelRoute:
		{
			if ( [aElementName isEqualToString:kGPXElemRoutePoint] )
			{
				// waypoint starts
				pointParsingLevel = kGPXPointParsingLevelBase;
				bypassPointParser = YES;
				
				outstandingPoint = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
									[aAttributes objectForKey:kGPXAttrPointLatitude], kGPXPointLatitude,
									[aAttributes objectForKey:kGPXAttrPointLongitude], kGPXPointLongitude,
									nil];
			}
			break;
		}
		
		case kGPXParsingLevelTrack:
		{
			if ( [aElementName isEqualToString:kGPXElemTrackSegment] )
			{
				// track segment starts
				parsingLevel = kGPXParsingLevelTrackSegment;

				[[tracks lastObject] addObject:[NSMutableArray array]];
			}			
			break;
		}
		
		case kGPXParsingLevelTrackSegment:
		{
			if ( [aElementName isEqualToString:kGPXElemTrackPoint] )
			{
				// waypoint starts
				pointParsingLevel = kGPXPointParsingLevelBase;
				bypassPointParser = YES;
				
				outstandingPoint = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
									[aAttributes objectForKey:kGPXAttrPointLatitude], kGPXPointLatitude,
									[aAttributes objectForKey:kGPXAttrPointLongitude], kGPXPointLongitude,
									nil];
			}
			break;
		}
	}

	if ( !bypassPointParser )
	{
		switch ( pointParsingLevel )
		{
			case kGPXPointParsingLevelBase:
			{
				if ( [aElementName isEqualToString:kGPXElemPointTime] )
				{
					pointParsingLevel = kGPXPointParsingLevelTime;
					
					// prepare to accept character data
					outstandingCharacters = [[NSMutableString alloc] init];
				}
				else if ( [aElementName isEqualToString:kGPXElemPointElevation] )
				{
					pointParsingLevel = kGPXPointParsingLevelElevation;
					
					// prepare to accept character data
					outstandingCharacters = [[NSMutableString alloc] init];
				}				
				break;
			}
		}
	}
}


// -----------------------------------------------------------------------------
// APGPXParser::parser:didEndElement:namespaceURI:qualifiedName:
// -----------------------------------------------------------------------------
- (void)parser:(NSXMLParser*)aParser didEndElement:(NSString*)aElementName 
  namespaceURI:(NSString*)aNamespaceURI qualifiedName:(NSString*)aQfdName
{
	BOOL bypassPointParsing = NO;
	
	switch ( parsingLevel )
	{
		case kGPXParsingLevelDocument:
		{
			// don't care
			break;
		}

		case kGPXParsingLevelBody:
		{
			if ( [aElementName isEqualToString:kGPXElemRoot] )
			{
				parsingLevel = kGPXParsingLevelDocument;
				bypassPointParsing = YES;
			}
			break;
		}
			
		case kGPXParsingLevelRoute:
		{
			if ( [aElementName isEqualToString:kGPXElemRoute] )
			{
				parsingLevel = kGPXParsingLevelBody;
				bypassPointParsing = YES;
			}
			break;
		}
			
		case kGPXParsingLevelTrack:
		{
			if ( [aElementName isEqualToString:kGPXElemTrack] )
			{
				parsingLevel = kGPXParsingLevelBody;
				bypassPointParsing = YES;
			}
			break;
		}
			
		case kGPXParsingLevelTrackSegment:
		{
			if ( [aElementName isEqualToString:kGPXElemTrackSegment] )
			{
				parsingLevel = kGPXParsingLevelTrack;
				bypassPointParsing = YES;
			}
			break;
		}
	}
	
	if ( !bypassPointParsing )
	{
		switch ( pointParsingLevel )
		{
			case kGPXPointParsingLevelBase:
			{
				if ( parsingLevel == kGPXParsingLevelBody && 
					 [aElementName isEqualToString:kGPXElemWaypoint] )
				{
					// waypoint closed
					[waypoints addObject:outstandingPoint];
					
					[outstandingPoint release];
					outstandingPoint = nil;
					
					pointParsingLevel = kGPXPointParsingLevelNone;
				}
				else if ( parsingLevel == kGPXParsingLevelRoute &&
						  [aElementName isEqualToString:kGPXElemRoutePoint] )
				{
					// route point closed
					[[routes lastObject] addObject:outstandingPoint];
					
					[outstandingPoint release];
					outstandingPoint = nil;

					pointParsingLevel = kGPXPointParsingLevelNone;
				}
				else if ( parsingLevel == kGPXParsingLevelTrackSegment &&
						  [aElementName isEqualToString:kGPXElemTrackPoint] )
				{
					// track point closed
					[[[tracks lastObject] lastObject] addObject:outstandingPoint];

					[outstandingPoint release];
					outstandingPoint = nil;

					pointParsingLevel = kGPXPointParsingLevelNone;
				}
				break;
			}
			
			case kGPXPointParsingLevelTime:
			{
				if ( [aElementName isEqualToString:kGPXElemPointTime] )
				{
					// time tag closed
					pointParsingLevel = kGPXPointParsingLevelBase;
					
					NSDateFormatter* dateFmt = [[NSDateFormatter alloc] init];
					[dateFmt setDateFormat:kGPXDateFormat];
					NSDate* pointTime = [dateFmt dateFromString:outstandingCharacters];
					[dateFmt release];
					
					[outstandingPoint setObject:pointTime forKey:kGPXPointTime];
					
					[outstandingCharacters release];
					outstandingCharacters = nil;
				}
				break;
			}

			case kGPXPointParsingLevelElevation:
			{
				if ( [aElementName isEqualToString:kGPXElemPointElevation] )
				{
					// time tag closed
					pointParsingLevel = kGPXPointParsingLevelBase;
					
					NSScanner* scanner = [NSScanner scannerWithString:outstandingCharacters];
					double value = 0;
					[scanner scanDouble:&value];
					
					[outstandingPoint setObject:[NSNumber numberWithDouble:value]
										 forKey:kGPXPointAltitude];
					
					[outstandingCharacters release];
					outstandingCharacters = nil;
				}
				break;
			}
		}
	}
	
//	printf("</%s>\n",[aQfdName cStringUsingEncoding:NSASCIIStringEncoding]);
}


// -----------------------------------------------------------------------------
// APGPXParser::parser:foundCharacters:
// -----------------------------------------------------------------------------
- (void)parser:(NSXMLParser*)aParser foundCharacters:(NSString*)aString
{
//	printf("\"%s\"\n",[aString cStringUsingEncoding:NSUTF8StringEncoding]);
	
	// simply append the new characters into the accumulation buffer
	[outstandingCharacters appendString:aString];
}



@end
