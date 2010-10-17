//
//  APAgentViewController.h
//  APAgent
//
//  Created by Lvsti on 2010.09.14..
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>


@class APUDPConnection;
@protocol APLocationDataSource;
@protocol APHeadingDataSource;


@interface APAgentViewController : UIViewController <CLLocationManagerDelegate, UITextFieldDelegate>
{
	CLLocationManager* locationManager;
	id<APLocationDataSource> locationDataSource;
	id<APHeadingDataSource> headingDataSource;
	APUDPConnection* udpConnection;
	
	BOOL isMonitoringLocation;
	BOOL isMonitoringHeading;
	BOOL isSending;
	
	NSDictionary* lastMessage;
	
	IBOutlet UITextField* ipAddress;
	IBOutlet UITextField* port;
	IBOutlet UIButton* toggleSending;
	
	IBOutlet UILabel* latitude;
	IBOutlet UILabel* longitude;
	IBOutlet UILabel* magHeading;
	IBOutlet UISwitch* toggleLocation;
	IBOutlet UISwitch* toggleHeading;
}

- (IBAction)toggleSending;
- (IBAction)toggleLocationMonitoring;
- (IBAction)toggleHeadingMonitoring;
- (IBAction)triggerSending;

@end

