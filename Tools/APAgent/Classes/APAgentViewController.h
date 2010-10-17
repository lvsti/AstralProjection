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


@interface APAgentViewController : UIViewController <CLLocationManagerDelegate, UITextFieldDelegate>
{
	CLLocationManager* locationManager;
	id<APLocationDataSource> locationDataSource;
	APUDPConnection* udpConnection;
	
	BOOL isMonitoring;
	BOOL isSending;
	
	NSDictionary* lastMessage;
	
	IBOutlet UITextField* ipAddress;
	IBOutlet UITextField* port;
	IBOutlet UIButton* toggleSending;
	
	IBOutlet UILabel* latitude;
	IBOutlet UILabel* longitude;
	IBOutlet UIButton* toggleMonitoring;
}

- (IBAction)toggleSending;
- (IBAction)toggleLocationMonitoring;
- (IBAction)triggerSending;

@end

