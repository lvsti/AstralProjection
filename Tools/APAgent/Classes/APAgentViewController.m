//
//  APAgentViewController.m
//  APAgent
//
//  Created by Lvsti on 2010.09.14..
//

#import "APAgentViewController.h"
#import "APUDPConnection.h"
#import "JSON.h"
#import "APLocationManager.h"
#import "APGPXDataSource.h"
#import "APHeadingDataSource.h"


#if defined(TARGET_IPHONE_SIMULATOR)
#undef LOCATION_HARDWARE_PRESENT
#else
// enable the GPS hardware here
//#define LOCATION_HARDWARE_PRESENT
#endif


static NSString* const kDateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
static NSString* const kLastIPKey = @"LastIP";
static NSString* const kLastPortKey = @"LastPort";



@implementation APAgentViewController


- (id)initWithCoder:(NSCoder*)aDecoder
{
	if ( (self = [super initWithCoder:aDecoder]) )
	{
#if defined(LOCATION_HARDWARE_PRESENT)
		locationManager = [[CLLocationManager alloc] init];
#else
		locationManager = [[APLocationManager alloc] init];
		
		APGPXDataSource* gpx = [[APGPXDataSource alloc] initWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ashland" ofType:@"gpx"]]];
		if ( [gpx cardinalityForDataSet:kAPGPXDataSetTrack] > 7 )
		{
			[gpx setActiveDataSet:kAPGPXDataSetTrack subsetIndex:7];
		}

		gpx.timeScale = 30.0;
		
		locationDataSource = gpx;
		locationDataSource.locationDataDelegate = (APLocationManager*)locationManager;
#endif

		locationManager.delegate = self;
		
		udpConnection = [[APUDPConnection alloc] init];
		
		isMonitoringLocation = NO;
		isMonitoringHeading = NO;
		isSending = NO;
	}
	
	return self;
}


- (void)dealloc
{
	[locationDataSource stopGeneratingLocationEvents];
	[locationDataSource release];
	
	[headingDataSource stopGeneratingHeadingEvents];
	[headingDataSource release];
	
	[locationManager stopUpdatingLocation];
	[locationManager release];

	[udpConnection release];
	[lastMessage release];
    [super dealloc];
}


- (void)viewDidLoad
{
	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	if ( [prefs objectForKey:kLastIPKey] )
	{
		ipAddress.text = [prefs objectForKey:kLastIPKey];
		[udpConnection setAddress:[prefs objectForKey:kLastIPKey]];
	}
	else
	{
		[udpConnection setAddress:@"127.0.0.1"];
	}
	
	if ( [prefs objectForKey:kLastPortKey] )
	{
		port.text = [[prefs objectForKey:kLastPortKey] stringValue];
		[udpConnection setPort:[[prefs objectForKey:kLastPortKey] intValue]];
	}
	else
	{
		[udpConnection setPort:0x6a7e];
	}
}


- (IBAction)toggleSending
{
	if ( !isSending )
	{
		[toggleSending setTitle:@"Stop sending" forState:UIControlStateNormal];
		isSending = YES;
	}
	else
	{
		[toggleSending setTitle:@"Start sending" forState:UIControlStateNormal];
		isSending = NO;
	}
}


- (IBAction)toggleHeadingMonitoring
{
	if ( toggleHeading.on )
	{
		[locationManager startUpdatingHeading];
		[headingDataSource startGeneratingHeadingEvents];
		isMonitoringHeading = YES;
	}
	else
	{
		[headingDataSource stopGeneratingHeadingEvents];
		[locationManager stopUpdatingHeading];
		isMonitoringHeading = NO;
	}
}


- (IBAction)toggleLocationMonitoring
{
	if ( toggleLocation.on )
	{
		[locationManager startUpdatingLocation];
		[locationDataSource startGeneratingLocationEvents];
		isMonitoringLocation = YES;
	}
	else
	{
		[locationDataSource stopGeneratingLocationEvents];
		[locationManager stopUpdatingLocation];
		isMonitoringLocation = NO;
	}
}


- (IBAction)triggerSending
{
	if ( lastMessage )
	{
		[udpConnection sendData:[[lastMessage JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
	}
}



#pragma mark -
#pragma mark from UITextFieldDelegate:

- (void)textFieldDidEndEditing:(UITextField*)aTextField
{
	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	
	if ( aTextField == port )
	{
		NSScanner* scanner = [NSScanner scannerWithString:port.text];
		int value = 0;
		[scanner scanInt:&value];
		
		[udpConnection setPort:value&0xffff];
		[prefs setObject:[NSNumber numberWithInt:value&0xffff] forKey:kLastPortKey];
	}
	else if ( aTextField == ipAddress )
	{
		[udpConnection setAddress:ipAddress.text];
		[prefs setObject:ipAddress.text forKey:kLastIPKey];
	}

	[prefs synchronize];
}


- (BOOL)textFieldShouldReturn:(UITextField*)aTextField
{
	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];

	if ( aTextField == port )
	{
		NSScanner* scanner = [NSScanner scannerWithString:port.text];
		int value = 0;
		[scanner scanInt:&value];
		
		[udpConnection setPort:value&0xffff];
		[prefs setObject:[NSNumber numberWithInt:value&0xffff] forKey:kLastPortKey];
	}
	else if ( aTextField == ipAddress )
	{
		[udpConnection setAddress:ipAddress.text];
		[prefs setObject:ipAddress.text forKey:kLastIPKey];
	}
	
	[prefs synchronize];
	
	[aTextField resignFirstResponder];
	
	return YES;
}


#pragma mark -
#pragma mark from CLLocationManagerDelegate:

- (void)locationManager:(CLLocationManager*)aManager
	didUpdateToLocation:(CLLocation*)aNewLocation
		   fromLocation:(CLLocation*)aOldLocation
{
	latitude.text = [NSString stringWithFormat:@"%3.5f",aNewLocation.coordinate.latitude];
	longitude.text = [NSString stringWithFormat:@"%3.5f",aNewLocation.coordinate.longitude];
	
	if ( isSending )
	{
		NSDateFormatter* dateFmt = [[NSDateFormatter alloc] init];
		[dateFmt setDateFormat:kDateFormat];
		
		NSDictionary* oldDic = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSNumber numberWithDouble:aOldLocation.coordinate.latitude], @"lat",
								[NSNumber numberWithDouble:aOldLocation.coordinate.longitude], @"lon",
								[NSNumber numberWithDouble:aOldLocation.altitude], @"alt",
								[NSNumber numberWithDouble:aOldLocation.horizontalAccuracy], @"hacc",
								[NSNumber numberWithDouble:aOldLocation.verticalAccuracy], @"vacc",
								[dateFmt stringFromDate:aOldLocation.timestamp], @"time",
								[NSNumber numberWithDouble:aOldLocation.speed], @"spd",
								[NSNumber numberWithDouble:aOldLocation.course], @"crs",
								nil];
		
		NSDictionary* newDic = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSNumber numberWithDouble:aNewLocation.coordinate.latitude], @"lat",
								[NSNumber numberWithDouble:aNewLocation.coordinate.longitude], @"lon",
								[NSNumber numberWithDouble:aNewLocation.altitude], @"alt",
								[NSNumber numberWithDouble:aNewLocation.horizontalAccuracy], @"hacc",
								[NSNumber numberWithDouble:aNewLocation.verticalAccuracy], @"vacc",
								[dateFmt stringFromDate:aNewLocation.timestamp], @"time",
								[NSNumber numberWithDouble:aNewLocation.speed], @"spd",
								[NSNumber numberWithDouble:aNewLocation.course], @"crs",
								nil];
		
		[dateFmt release];
		
		NSDictionary* message = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"update.location", @"type",
								 [NSDictionary dictionaryWithObjectsAndKeys:
								  oldDic, @"old",
								  newDic, @"new",
								  nil], @"data",
								 nil];
		
		[lastMessage release];
		lastMessage = [message retain];
		
		[udpConnection sendData:[[message JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
		NSLog(@"location update sent");
	}
}


- (void)locationManager:(CLLocationManager*)aManager
	   didFailWithError:(NSError*)aError
{
	if ( isSending )
	{
		NSDictionary* packet = [NSDictionary dictionaryWithObjectsAndKeys:
								@"error", @"type",
								[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:aError.code], @"code",
								 aError.domain, @"domain",
								 aError.userInfo, @"userInfo",
								 nil], @"data",
								nil];
		
		[udpConnection sendData:[[packet JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
	}
}


- (void)locationManager:(CLLocationManager*)aManager
	   didUpdateHeading:(CLHeading*)aHeading
{
	if ( isSending )
	{
		NSDateFormatter* dateFmt = [[NSDateFormatter alloc] init];
		[dateFmt setDateFormat:kDateFormat];
		
		NSDictionary* packet = [NSDictionary dictionaryWithObjectsAndKeys:
								@"update.heading", @"type",
								[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithDouble:aHeading.magneticHeading], @"mag",
								 [NSNumber numberWithDouble:aHeading.trueHeading], @"true",
								 [NSNumber numberWithDouble:aHeading.headingAccuracy], @"acc",
								 [dateFmt stringFromDate:aHeading.timestamp], @"time",
								 [NSNumber numberWithDouble:aHeading.x], @"x",
								 [NSNumber numberWithDouble:aHeading.y], @"y",
								 [NSNumber numberWithDouble:aHeading.z], @"z",
								 nil], @"data",
								nil];
		
		[udpConnection sendData:[[packet JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
		NSLog(@"heading update sent");
	}
}


@end
