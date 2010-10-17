//
//  APHostViewController.h
//  APHost
//
//  Created by Lvsti on 2010.09.16..
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@protocol APLocationDataSource;


@interface APHostViewController : UIViewController <CLLocationManagerDelegate>
{
	CLLocationManager* locationManager;
	BOOL isUpdatingLocation;
	
	IBOutlet UILabel* latitude;
	IBOutlet UILabel* longitude;
	IBOutlet UIButton* toggleUpdatesButton;
	
	id<APLocationDataSource> locationDataSource;
}

- (IBAction)toggleLocationUpdates;


@end

