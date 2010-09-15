//
//  APAgentViewController.h
//  APAgent
//
//  Created by Lvsti on 2010.09.14..
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>


@class APUDPConnection;


@interface APAgentViewController : UIViewController <CLLocationManagerDelegate, UITextFieldDelegate>
{
	CLLocationManager* locationManager;
	APUDPConnection* udpConnection;
	
	BOOL isMonitoring;
	BOOL isSending;
	
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

