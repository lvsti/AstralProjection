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


@interface ViewController () <APAstralProjectionDelegate, CLLocationManagerDelegate>
{
	CLLocationManager* locMgr;
	BOOL isUpdatingLocation;
	BOOL isDataSourceActive;
	id<APLocationDataSource> locationDataSource;
}

@property (assign, nonatomic) IBOutlet MKMapView *mapView;
@property (assign, nonatomic) IBOutlet UILabel *latLabel;
@property (assign, nonatomic) IBOutlet UILabel *longLabel;
@property (assign, nonatomic) IBOutlet UILabel *altLabel;
@property (assign, nonatomic) IBOutlet UILabel *magHeadLabel;
@property (assign, nonatomic) IBOutlet UILabel *trueHeadLabel;
@property (assign, nonatomic) IBOutlet UIButton *datasourceButton;
@property (assign, nonatomic) IBOutlet UIButton *updateButton;

@end

@implementation ViewController

@synthesize mapView;
@synthesize latLabel;
@synthesize longLabel;
@synthesize altLabel;
@synthesize magHeadLabel;
@synthesize trueHeadLabel;
@synthesize datasourceButton;
@synthesize updateButton;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if ( self != nil )
	{
		APGPXDataSource* gpx = [[[APGPXDataSource alloc] initWithURL:
								 [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ashland.gpx" ofType:nil]]] autorelease];
		[gpx setActiveDataSet:kAPGPXDataSetTrack subsetIndex:7];
		gpx.timeScale = 1;
		gpx.eventFrequency = 0.25;
		gpx.autorepeat = YES;
		
		locationDataSource = [gpx retain];
		[APAstralProjection sharedInstance].delegate = self;
		[APAstralProjection sharedInstance].locationDataSource = gpx;
		
		locMgr = [[CLLocationManager alloc] init];
		locMgr.delegate = self;
	}
	
	return self;
}


- (void)dealloc
{
	[locationDataSource release];
	[super dealloc];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	
	mapView.showsUserLocation = YES;
	mapView.userTrackingMode = MKUserTrackingModeFollowWithHeading;
}


- (void)viewDidUnload
{
	[self setMapView:nil];
	[self setLatLabel:nil];
	[self setLongLabel:nil];
	[self setAltLabel:nil];
	[self setMagHeadLabel:nil];
	[self setTrueHeadLabel:nil];
	[self setDatasourceButton:nil];
	[self setUpdateButton:nil];
	[super viewDidUnload];
}


- (IBAction)datasourceButtonTapped:(id)sender
{
	if ( !isDataSourceActive )
	{
		[datasourceButton setTitle:@"Stop datasource" forState:UIControlStateNormal];
		[[APAstralProjection sharedInstance].locationDataSource startGeneratingLocationEvents];
	}
	else
	{
		[updateButton setTitle:@"Restart datasource" forState:UIControlStateNormal];
		[[APAstralProjection sharedInstance].locationDataSource stopGeneratingLocationEvents];
	}
	
	isDataSourceActive = !isDataSourceActive;
}


- (IBAction)updateButtonTapped:(id)sender
{
	if ( !isUpdatingLocation )
	{
		[updateButton setTitle:@"Stop updates" forState:UIControlStateNormal];
		[locMgr startUpdatingLocation];
	}
	else
	{
		[updateButton setTitle:@"Start updates" forState:UIControlStateNormal];
		[locMgr stopUpdatingLocation];
	}
	
	isUpdatingLocation = !isUpdatingLocation;
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
	latLabel.text = [NSString stringWithFormat:@"%3.5f",newLocation.coordinate.latitude];
	longLabel.text = [NSString stringWithFormat:@"%3.5f",newLocation.coordinate.longitude];
	altLabel.text = [NSString stringWithFormat:@"%4.2f",newLocation.altitude];
}


- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error
{
}


- (void)locationManager:(CLLocationManager *)manager
	   didUpdateHeading:(CLHeading *)newHeading
{
	magHeadLabel.text = [NSString stringWithFormat:@"%3.2f",newHeading.magneticHeading];
	trueHeadLabel.text = [NSString stringWithFormat:@"%3.2f",newHeading.trueHeading];
}


@end
