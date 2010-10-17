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


#if defined(TARGET_IPHONE_SIMULATOR)
#undef LOCATION_HARDWARE_PRESENT
#else
// enable the GPS hardware here
//#define LOCATION_HARDWARE_PRESENT
#endif


static NSString* const kDateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";



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
		[udpConnection setAddress:@"127.0.0.1"];
		[udpConnection setPort:0x6a7e];
		
		isMonitoring = NO;
		isSending = NO;
	}
	
	return self;
}


- (void)dealloc
{
	[locationDataSource stopGeneratingLocationEvents];
	[locationDataSource release];
	
	[locationManager stopUpdatingLocation];
	[locationManager release];

	[udpConnection release];
	[lastMessage release];
    [super dealloc];
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


- (IBAction)toggleLocationMonitoring
{
	if ( !isMonitoring )
	{
		[locationManager startUpdatingLocation];
		[locationDataSource startGeneratingLocationEvents];
		[toggleMonitoring setTitle:@"Stop monitoring" forState:UIControlStateNormal];
		isMonitoring = YES;
	}
	else
	{
		[locationDataSource stopGeneratingLocationEvents];
		[locationManager stopUpdatingLocation];
		[toggleMonitoring setTitle:@"Start monitoring" forState:UIControlStateNormal];
		isMonitoring = NO;
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
	if ( aTextField == port )
	{
		NSScanner* scanner = [NSScanner scannerWithString:port.text];
		int value = 0;
		[scanner scanInt:&value];
		
		[udpConnection setPort:value&0xffff];
	}
	else if ( aTextField == ipAddress )
	{
		[udpConnection setAddress:ipAddress.text];
	}
}


- (BOOL)textFieldShouldReturn:(UITextField*)aTextField
{
	if ( aTextField == port )
	{
		NSScanner* scanner = [NSScanner scannerWithString:port.text];
		int value = 0;
		[scanner scanInt:&value];
		
		[udpConnection setPort:value&0xffff];
	}
	else if ( aTextField == ipAddress )
	{
		[udpConnection setAddress:ipAddress.text];
	}
	
	
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
								 @"update", @"type",
								 [NSDictionary dictionaryWithObjectsAndKeys:
								  oldDic, @"old",
								  newDic, @"new",
								  nil], @"data",
								 nil];
		
		[lastMessage release];
		lastMessage = [message retain];
		
		[udpConnection sendData:[[message JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
		NSLog(@"update sent");
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

@end
