//
//  ViewController.m
//  APMobileHost
//
//  Created by Tamas Lustyik on 2013.07.19..
//  Copyright (c) 2013 LKXF Studios. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "APAstralProjection.h"
#import "APGPXDataSource.h"
#import "APAgentDataSource.h"


@interface ViewController () <APAstralProjectionDelegate, CLLocationManagerDelegate>
{
	CLLocationManager* _locMgr;
	BOOL _isUpdatingLocation;
	BOOL _isDataSourceActive;
	id<APLocationDataSource> _locationDataSource;
}

@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, weak) IBOutlet UILabel *latLabel;
@property (nonatomic, weak) IBOutlet UILabel *longLabel;
@property (nonatomic, weak) IBOutlet UILabel *altLabel;
@property (nonatomic, weak) IBOutlet UILabel *magHeadLabel;
@property (nonatomic, weak) IBOutlet UILabel *trueHeadLabel;
@property (nonatomic, weak) IBOutlet UIButton *datasourceButton;
@property (nonatomic, weak) IBOutlet UIButton *updateButton;

@end

@implementation ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self)
	{
		/*/
		APGPXDataSource* gpx = [[[APGPXDataSource alloc] initWithURL:
								 [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ashland.gpx" ofType:nil]]] autorelease];
		[gpx setActiveDataSet:kAPGPXDataSetTrack subsetIndex:7];
		gpx.timeScale = 1;
		gpx.eventFrequency = 0.25;
		gpx.autorepeat = YES;

		locationDataSource = [gpx retain];
		[APAstralProjection sharedInstance].locationDataSource = gpx;

		/*/
		
		APAgentDataSource* agent = [[APAgentDataSource alloc] initWithUDPPort:0x1234];
		_locationDataSource = agent;
		[APAstralProjection sharedInstance].locationDataSource = agent;
		
		//*/

		[APAstralProjection sharedInstance].delegate = self;
		
		_locMgr = [CLLocationManager new];
		_locMgr.delegate = self;
	}
	
	return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	
	_mapView.showsUserLocation = YES;
	_mapView.userTrackingMode = MKUserTrackingModeFollowWithHeading;
}


- (IBAction)datasourceButtonTapped:(id)sender
{
	if (!_isDataSourceActive)
	{
		[_datasourceButton setTitle:@"Stop datasource" forState:UIControlStateNormal];
		[[APAstralProjection sharedInstance].locationDataSource startGeneratingLocationEvents];
	}
	else
	{
		[_datasourceButton setTitle:@"Restart datasource" forState:UIControlStateNormal];
		[[APAstralProjection sharedInstance].locationDataSource stopGeneratingLocationEvents];
	}
	
	_isDataSourceActive = !_isDataSourceActive;
}


- (IBAction)updateButtonTapped:(id)sender
{
	if (!_isUpdatingLocation)
	{
		[_updateButton setTitle:@"Stop updates" forState:UIControlStateNormal];
		[_locMgr startUpdatingLocation];
	}
	else
	{
		[_updateButton setTitle:@"Start updates" forState:UIControlStateNormal];
		[_locMgr stopUpdatingLocation];
	}
	
	_isUpdatingLocation = !_isUpdatingLocation;
}


#pragma mark - from APAstralProjectionDelegate:


- (CLAuthorizationStatus)astralAuthorizationStatus
{
	return kCLAuthorizationStatusAuthorized;
}


- (BOOL)astralLocationServicesEnabled
{
	return YES;
}


#pragma mark - from CLLocationManagerDelegate:

- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation
{
	_latLabel.text = [NSString stringWithFormat:@"%3.5f",newLocation.coordinate.latitude];
	_longLabel.text = [NSString stringWithFormat:@"%3.5f",newLocation.coordinate.longitude];
	_altLabel.text = [NSString stringWithFormat:@"%4.2f",newLocation.altitude];
}


- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error
{
}


- (void)locationManager:(CLLocationManager *)manager
	   didUpdateHeading:(CLHeading *)newHeading
{
	_magHeadLabel.text = [NSString stringWithFormat:@"%3.2f",newHeading.magneticHeading];
	_trueHeadLabel.text = [NSString stringWithFormat:@"%3.2f",newHeading.trueHeading];
}


@end
