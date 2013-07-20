//
//  APAgentViewController.m
//  APAgent
//
//  Created by Lvsti on 2010.09.14..
//

#import "APAgentViewController.h"

#import <CoreLocation/CoreLocation.h>
#import "APHeadingDataSource.h"
#import "APUDPConnection.h"
#import "JSON.h"


#define LOCATION_HARDWARE_PRESENT	1

#if TARGET_IPHONE_SIMULATOR
#undef LOCATION_HARDWARE_PRESENT
#define LOCATION_HARDWARE_PRESENT	0
#endif

#if !LOCATION_HARDWARE_PRESENT
#import "APAstralProjection.h"
#import "APGPXDataSource.h"
#endif


static NSString* const kDateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
static NSString* const kLastIPKey = @"LastIP";
static NSString* const kLastPortKey = @"LastPort";


#if LOCATION_HARDWARE_PRESENT
@interface APAgentViewController () <CLLocationManagerDelegate, UITextFieldDelegate>
#else
@interface APAgentViewController () <CLLocationManagerDelegate, UITextFieldDelegate, APAstralProjectionDelegate>
#endif
{
	CLLocationManager* locationManager;
	APUDPConnection* udpConnection;
	
	BOOL isMonitoringLocation;
	BOOL isMonitoringHeading;
	BOOL isSending;
	
	NSDictionary* lastMessage;

#if !LOCATION_HARDWARE_PRESENT
	id<APLocationDataSource> locationDataSource;
	id<APHeadingDataSource> headingDataSource;
#endif
}
@property (nonatomic, assign) IBOutlet UITextField* addressField;
@property (nonatomic, assign) IBOutlet UITextField* portField;
@property (nonatomic, assign) IBOutlet UIButton* toggleSendingButton;

@property (nonatomic, assign) IBOutlet UILabel* latLabel;
@property (nonatomic, assign) IBOutlet UILabel* longLabel;
@property (nonatomic, assign) IBOutlet UILabel* magHeadingLabel;
@property (nonatomic, assign) IBOutlet UILabel* trueHeadingLabel;
@property (nonatomic, assign) IBOutlet UISwitch* locationSwitch;
@property (nonatomic, assign) IBOutlet UISwitch* headingSwitch;

- (IBAction)toggleSendingTapped;
- (IBAction)locationMonitoringSwitchTapped;
- (IBAction)headingMonitoringSwitchTapped;
- (IBAction)triggerSendingTapped;

@end


@implementation APAgentViewController

@synthesize addressField;
@synthesize portField;
@synthesize toggleSendingButton;
@synthesize latLabel;
@synthesize longLabel;
@synthesize magHeadingLabel;
@synthesize trueHeadingLabel;
@synthesize locationSwitch;
@synthesize headingSwitch;


- (id)initWithCoder:(NSCoder*)aDecoder
{
	if ( (self = [super initWithCoder:aDecoder]) )
	{
#if !LOCATION_HARDWARE_PRESENT
		APGPXDataSource* gpx = [[[APGPXDataSource alloc] initWithURL:
								 [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ashland" ofType:@"gpx"]]] autorelease];
		if ( [gpx cardinalityForDataSet:kAPGPXDataSetTrack] > 7 )
		{
			[gpx setActiveDataSet:kAPGPXDataSetTrack subsetIndex:7];
		}

		gpx.timeScale = 1.0;
		gpx.eventFrequency = 0.25;
		
		locationDataSource = [gpx retain];
		[APAstralProjection sharedInstance].locationDataSource = gpx;

		// optionally, set up heading data source here
		//...
		//[APAstralProjection sharedInstance].headingDataSource = ...
		
		[APAstralProjection sharedInstance].delegate = self;
#endif

		locationManager = [[CLLocationManager alloc] init];
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
#if !LOCATION_HARDWARE_PRESENT
	[locationDataSource stopGeneratingLocationEvents];
	[locationDataSource release];
	
	[headingDataSource stopGeneratingHeadingEvents];
	[headingDataSource release];
#endif
	
	[locationManager stopUpdatingLocation];
	[locationManager stopUpdatingHeading];
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
		addressField.text = [prefs objectForKey:kLastIPKey];
		[udpConnection setAddress:[prefs objectForKey:kLastIPKey]];
	}
	else
	{
		[udpConnection setAddress:@"127.0.0.1"];
	}
	
	if ( [prefs objectForKey:kLastPortKey] )
	{
		portField.text = [[prefs objectForKey:kLastPortKey] stringValue];
		[udpConnection setPort:[[prefs objectForKey:kLastPortKey] intValue]];
	}
	else
	{
		[udpConnection setPort:0x6a7e];
	}
}


- (IBAction)toggleSendingTapped
{
	if ( !isSending )
	{
		[toggleSendingButton setTitle:@"Stop sending" forState:UIControlStateNormal];
		isSending = YES;
	}
	else
	{
		[toggleSendingButton setTitle:@"Start sending" forState:UIControlStateNormal];
		isSending = NO;
	}
}


- (IBAction)headingMonitoringSwitchTapped
{
	if ( headingSwitch.on )
	{
		[locationManager startUpdatingHeading];
#if !LOCATION_HARDWARE_PRESENT
		[headingDataSource startGeneratingHeadingEvents];
#endif
		isMonitoringHeading = YES;
	}
	else
	{
#if !LOCATION_HARDWARE_PRESENT
		[headingDataSource stopGeneratingHeadingEvents];
#endif
		[locationManager stopUpdatingHeading];
		isMonitoringHeading = NO;
	}
}


- (IBAction)locationMonitoringSwitchTapped
{
	if ( locationSwitch.on )
	{
		[locationManager startUpdatingLocation];
#if !LOCATION_HARDWARE_PRESENT
		[locationDataSource startGeneratingLocationEvents];
#endif
		isMonitoringLocation = YES;
	}
	else
	{
#if !LOCATION_HARDWARE_PRESENT
		[locationDataSource stopGeneratingLocationEvents];
#endif
		[locationManager stopUpdatingLocation];
		isMonitoringLocation = NO;
	}
}


- (IBAction)triggerSendingTapped
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
	
	if ( aTextField == portField )
	{
		NSScanner* scanner = [NSScanner scannerWithString:portField.text];
		int value = 0;
		[scanner scanInt:&value];
		
		[udpConnection setPort:value&0xffff];
		[prefs setObject:[NSNumber numberWithInt:value&0xffff] forKey:kLastPortKey];
	}
	else if ( aTextField == addressField )
	{
		[udpConnection setAddress:addressField.text];
		[prefs setObject:addressField.text forKey:kLastIPKey];
	}

	[prefs synchronize];
}


- (BOOL)textFieldShouldReturn:(UITextField*)aTextField
{
	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];

	if ( aTextField == portField )
	{
		NSScanner* scanner = [NSScanner scannerWithString:portField.text];
		int value = 0;
		[scanner scanInt:&value];
		
		[udpConnection setPort:value&0xffff];
		[prefs setObject:[NSNumber numberWithInt:value&0xffff] forKey:kLastPortKey];
	}
	else if ( aTextField == addressField )
	{
		[udpConnection setAddress:addressField.text];
		[prefs setObject:addressField.text forKey:kLastIPKey];
	}
	
	[prefs synchronize];
	
	[aTextField resignFirstResponder];
	
	return YES;
}


#if !LOCATION_HARDWARE_PRESENT

#pragma mark - from APAstralProjectionDelegate:

- (CLAuthorizationStatus)astralAuthorizationStatus
{
	return kCLAuthorizationStatusAuthorized;
}


- (BOOL)astralLocationServicesEnabled
{
	return YES;
}

#endif


#pragma mark -
#pragma mark from CLLocationManagerDelegate:

- (void)locationManager:(CLLocationManager*)aManager
	didUpdateToLocation:(CLLocation*)aNewLocation
		   fromLocation:(CLLocation*)aOldLocation
{
	latLabel.text = [NSString stringWithFormat:@"%3.5f",aNewLocation.coordinate.latitude];
	longLabel.text = [NSString stringWithFormat:@"%3.5f",aNewLocation.coordinate.longitude];
	
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
