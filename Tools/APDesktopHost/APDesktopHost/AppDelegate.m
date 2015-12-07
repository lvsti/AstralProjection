//
//  AppDelegate.m
//  APDesktopHost
//
//  Created by Tamas Lustyik on 2013.07.18..
//  Copyright (c) 2013 LKXF Studios. All rights reserved.
//

#import "AppDelegate.h"
#import <CoreLocation/CoreLocation.h>
#import "APAstralProjection.h"
#import "APGPXDataSource.h"

@interface AppDelegate () <APAstralProjectionDelegate, CLLocationManagerDelegate>
{
	CLLocationManager* _locMgr;
	BOOL _isUpdatingLocation;
	BOOL _isDataSourceActive;
	id<APLocationDataSource> _locationDataSource;
}

@property (nonatomic, weak) IBOutlet NSButton *updateButton;
@property (nonatomic, weak) IBOutlet NSButton *datasourceButton;
@property (nonatomic, weak) IBOutlet NSTextField *latLabel;
@property (nonatomic, weak) IBOutlet NSTextField *longLabel;
@property (nonatomic, weak) IBOutlet NSTextField *altLabel;

@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSURL* gpxURL = [[NSBundle mainBundle] URLForResource:@"ashland" withExtension:@"gpx"];
	APGPXDataSource* gpx = [[APGPXDataSource alloc] initWithContentsOfURL:gpxURL];
	[gpx setActiveDataSet:kAPGPXDataSetTrack subsetIndex:7];
	gpx.timeScale = 1;
	gpx.eventFrequency = 0.25;
	gpx.autorepeat = YES;

    _locationDataSource = gpx;
	[APAstralProjection sharedInstance].delegate = self;
	[APAstralProjection sharedInstance].locationDataSource = gpx;

	_locMgr = [CLLocationManager new];
	_locMgr.delegate = self;
}


- (IBAction)updateButtonClicked:(id)sender
{
	if (!_isUpdatingLocation)
	{
		_updateButton.title = @"Stop updates";
		[_locMgr startUpdatingLocation];
	}
	else
	{
		_updateButton.title = @"Start updates";
		[_locMgr stopUpdatingLocation];
	}
	
	_isUpdatingLocation = !_isUpdatingLocation;
}


- (IBAction)datasourceButtonClicked:(id)sender
{
	if (!_isDataSourceActive)
	{
		_datasourceButton.title = @"Stop datasource";
		[[APAstralProjection sharedInstance].locationDataSource startGeneratingLocationEvents];
	}
	else
	{
		_datasourceButton.title = @"Restart datasource";
		[[APAstralProjection sharedInstance].locationDataSource stopGeneratingLocationEvents];
	}
	
	_isDataSourceActive = !_isDataSourceActive;
}


- (CLAuthorizationStatus)astralAuthorizationStatus
{
	return kCLAuthorizationStatusAuthorized;
}


- (BOOL)astralLocationServicesEnabled
{
	return YES;
}


- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation
{
    _latLabel.stringValue = [NSString stringWithFormat:@"%3.5f",newLocation.coordinate.latitude];
	_longLabel.stringValue = [NSString stringWithFormat:@"%3.5f",newLocation.coordinate.longitude];
	_altLabel.stringValue = [NSString stringWithFormat:@"%4.2f",newLocation.altitude];
}


@end
