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
	CLLocationManager* _locationManager;
	APUDPConnection* _udpConnection;
	
	BOOL _isMonitoringLocation;
	BOOL _isMonitoringHeading;
	BOOL _isSending;
	
	NSDictionary* _lastMessage;
	NSDateFormatter* _dateFmt;

#if !LOCATION_HARDWARE_PRESENT
	id<APLocationDataSource> _locationDataSource;
	id<APHeadingDataSource> _headingDataSource;
#endif
}
@property (nonatomic, weak) IBOutlet UITextField* addressField;
@property (nonatomic, weak) IBOutlet UITextField* portField;
@property (nonatomic, weak) IBOutlet UIButton* toggleSendingButton;

@property (nonatomic, weak) IBOutlet UILabel* latLabel;
@property (nonatomic, weak) IBOutlet UILabel* longLabel;
@property (nonatomic, weak) IBOutlet UILabel* magHeadingLabel;
@property (nonatomic, weak) IBOutlet UILabel* trueHeadingLabel;
@property (nonatomic, weak) IBOutlet UISwitch* locationSwitch;
@property (nonatomic, weak) IBOutlet UISwitch* headingSwitch;

@end


@implementation APAgentViewController

- (id)initWithCoder:(NSCoder*)aDecoder
{
	if ( (self = [super initWithCoder:aDecoder]) )
	{
#if !LOCATION_HARDWARE_PRESENT
        NSURL* gpxURL = [[NSBundle mainBundle] URLForResource:@"ashland" withExtension:@"gpx"];
		APGPXDataSource* gpx = [[APGPXDataSource alloc] initWithContentsOfURL:gpxURL];
		if ([gpx cardinalityForDataSet:kAPGPXDataSetTrack] > 7)
		{
			[gpx setActiveDataSet:kAPGPXDataSetTrack subsetIndex:7];
		}

		gpx.timeScale = 1.0;
		gpx.eventFrequency = 0.25;
		
        _locationDataSource = gpx;
		[APAstralProjection sharedInstance].locationDataSource = gpx;

		// optionally, set up heading data source here
		//...
		//[APAstralProjection sharedInstance].headingDataSource = ...
		
		[APAstralProjection sharedInstance].delegate = self;
#endif

		_locationManager = [CLLocationManager new];
		_locationManager.delegate = self;
		
		_udpConnection = [APUDPConnection new];
		
		_dateFmt = [NSDateFormatter new];
        _dateFmt.dateFormat = kDateFormat;

		_isMonitoringLocation = NO;
		_isMonitoringHeading = NO;
		_isSending = NO;
	}
	
	return self;
}


- (void)dealloc
{
#if !LOCATION_HARDWARE_PRESENT
	[_locationDataSource stopGeneratingLocationEvents];
	
	[_headingDataSource stopGeneratingHeadingEvents];
#endif
	
	[_locationManager stopUpdatingLocation];
	[_locationManager stopUpdatingHeading];
}


- (void)viewDidLoad
{
	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	if ([prefs objectForKey:kLastIPKey])
	{
		_addressField.text = [prefs objectForKey:kLastIPKey];
        _udpConnection.ipAddress = [prefs objectForKey:kLastIPKey];
	}
	else
	{
        _udpConnection.ipAddress = @"127.0.0.1";
	}
	
	if ( [prefs objectForKey:kLastPortKey] )
	{
		_portField.text = [[prefs objectForKey:kLastPortKey] stringValue];
		[_udpConnection setPort:[[prefs objectForKey:kLastPortKey] intValue]];
	}
	else
	{
		[_udpConnection setPort:0x6a7e];
	}
}


- (IBAction)toggleSendingTapped
{
	if (!_isSending)
	{
		[_toggleSendingButton setTitle:@"Stop sending" forState:UIControlStateNormal];
		_isSending = YES;
	}
	else
	{
		[_toggleSendingButton setTitle:@"Start sending" forState:UIControlStateNormal];
		_isSending = NO;
	}
}


- (IBAction)headingMonitoringSwitchTapped
{
	if (_headingSwitch.on)
	{
		[_locationManager startUpdatingHeading];
#if !LOCATION_HARDWARE_PRESENT
		[_headingDataSource startGeneratingHeadingEvents];
#endif
		_isMonitoringHeading = YES;
	}
	else
	{
#if !LOCATION_HARDWARE_PRESENT
		[_headingDataSource stopGeneratingHeadingEvents];
#endif
		[_locationManager stopUpdatingHeading];
		_isMonitoringHeading = NO;
	}
}


- (IBAction)locationMonitoringSwitchTapped
{
	if (_locationSwitch.on)
	{
		[_locationManager startUpdatingLocation];
#if !LOCATION_HARDWARE_PRESENT
		[_locationDataSource startGeneratingLocationEvents];
#endif
		_isMonitoringLocation = YES;
	}
	else
	{
#if !LOCATION_HARDWARE_PRESENT
		[_locationDataSource stopGeneratingLocationEvents];
#endif
		[_locationManager stopUpdatingLocation];
		_isMonitoringLocation = NO;
	}
}


- (IBAction)triggerSendingTapped
{
	if (_lastMessage)
	{
		NSData* jsonData = [NSJSONSerialization dataWithJSONObject:_lastMessage
														   options:0
															 error:NULL];
		[_udpConnection sendData:jsonData];
	}
}


#pragma mark - from UITextFieldDelegate:


- (void)textFieldDidEndEditing:(UITextField*)aTextField
{
	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	
	if (aTextField == _portField)
	{
		NSScanner* scanner = [NSScanner scannerWithString:_portField.text];
		int value = 0;
		[scanner scanInt:&value];
		
		_udpConnection.port = value & 0xffff;
        [prefs setInteger:_udpConnection.port forKey:kLastPortKey];
	}
	else if (aTextField == _addressField)
	{
		_udpConnection.ipAddress = _addressField.text;
		[prefs setObject:_addressField.text forKey:kLastIPKey];
	}

	[prefs synchronize];
}


- (BOOL)textFieldShouldReturn:(UITextField*)aTextField
{
	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];

	if (aTextField == _portField)
	{
		NSScanner* scanner = [NSScanner scannerWithString:_portField.text];
		int value = 0;
		[scanner scanInt:&value];
		
		_udpConnection.port = value & 0xffff;
        [prefs setInteger:_udpConnection.port forKey:kLastPortKey];
	}
	else if (aTextField == _addressField)
	{
		_udpConnection.ipAddress = _addressField.text;
		[prefs setObject:_addressField.text forKey:kLastIPKey];
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
	_latLabel.text = [NSString stringWithFormat:@"%3.5f",aNewLocation.coordinate.latitude];
	_longLabel.text = [NSString stringWithFormat:@"%3.5f",aNewLocation.coordinate.longitude];
	
	if (_isSending)
	{
        NSDictionary* oldDic = @{
            @"lat": @(aOldLocation.coordinate.latitude),
            @"lon": @(aOldLocation.coordinate.longitude),
            @"alt": @(aOldLocation.altitude),
            @"hacc": @(aOldLocation.horizontalAccuracy),
            @"vacc": @(aOldLocation.verticalAccuracy),
            @"time": [_dateFmt stringFromDate:aOldLocation.timestamp],
            @"spd": @(aOldLocation.speed),
            @"crs": @(aOldLocation.course)
        };
		
		NSDictionary* newDic = @{
            @"lat": @(aNewLocation.coordinate.latitude),
            @"lon": @(aNewLocation.coordinate.longitude),
            @"alt": @(aNewLocation.altitude),
            @"hacc": @(aNewLocation.horizontalAccuracy),
            @"vacc": @(aNewLocation.verticalAccuracy),
            @"time": [_dateFmt stringFromDate:aNewLocation.timestamp],
            @"spd": @(aNewLocation.speed),
            @"crs": @(aNewLocation.course)
        };
		
        NSDictionary* message = @{
            @"type": @"update.location",
            @"data": @{
                @"old": oldDic,
                @"new": newDic,
        }};
		
		_lastMessage = message;
		
		NSData* jsonData = [NSJSONSerialization dataWithJSONObject:_lastMessage
														   options:0
															 error:NULL];

		[_udpConnection sendData:jsonData];
		NSLog(@"location update sent");
	}
}


- (void)locationManager:(CLLocationManager*)aManager
	   didFailWithError:(NSError*)aError
{
	if (_isSending)
	{
		NSDictionary* packet = @{
            @"type": @"error",
            @"data": @{@"code": @(aError.code),
                       @"domain": aError.domain,
                       @"userInfo": aError.userInfo}
        };
		
		NSData* jsonData = [NSJSONSerialization dataWithJSONObject:packet
														   options:0
															 error:NULL];
		[_udpConnection sendData:jsonData];
	}
}


- (void)locationManager:(CLLocationManager*)aManager
	   didUpdateHeading:(CLHeading*)aHeading
{
	if (_isSending)
	{
		NSDictionary* packet = @{
            @"type": @"update.heading",
            @"data": @{
                @"mag": @(aHeading.magneticHeading),
                @"true": @(aHeading.trueHeading),
                @"acc": @(aHeading.headingAccuracy),
                @"time": [_dateFmt stringFromDate:aHeading.timestamp],
                @"x": @(aHeading.x),
                @"y": @(aHeading.y),
                @"z": @(aHeading.z)
            }
        };
		
		NSData* jsonData = [NSJSONSerialization dataWithJSONObject:packet
														   options:0
															 error:NULL];
		[_udpConnection sendData:jsonData];
		NSLog(@"heading update sent");
	}
}


@end
