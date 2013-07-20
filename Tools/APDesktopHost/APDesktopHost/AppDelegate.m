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
	CLLocationManager* locMgr;
	BOOL isUpdatingLocation;
	BOOL isDataSourceActive;
	id<APLocationDataSource> locationDataSource;
}

@property (assign) IBOutlet NSButton *updateButton;
@property (assign) IBOutlet NSButton *datasourceButton;
@property (assign) IBOutlet NSTextField *latLabel;
@property (assign) IBOutlet NSTextField *longLabel;
@property (assign) IBOutlet NSTextField *altLabel;

@end


@implementation AppDelegate

@synthesize updateButton;
@synthesize datasourceButton;
@synthesize latLabel;
@synthesize longLabel;
@synthesize altLabel;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
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


- (void)dealloc
{
	[locationDataSource release];
    [super dealloc];
}


- (IBAction)updateButtonClicked:(id)sender
{
	if ( !isUpdatingLocation )
	{
		[updateButton setTitle:@"Stop updates"];
		[locMgr startUpdatingLocation];
	}
	else
	{
		[updateButton setTitle:@"Start updates"];
		[locMgr stopUpdatingLocation];
	}
	
	isUpdatingLocation = !isUpdatingLocation;
}


- (IBAction)datasourceButtonClicked:(id)sender
{
	if ( !isDataSourceActive )
	{
		[datasourceButton setTitle:@"Stop datasource"];
		[[APAstralProjection sharedInstance].locationDataSource startGeneratingLocationEvents];
	}
	else
	{
		[datasourceButton setTitle:@"Restart datasource"];
		[[APAstralProjection sharedInstance].locationDataSource stopGeneratingLocationEvents];
	}
	
	isDataSourceActive = !isDataSourceActive;
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
	[latLabel setStringValue:[NSString stringWithFormat:@"%3.5f",newLocation.coordinate.latitude]];
	[longLabel setStringValue:[NSString stringWithFormat:@"%3.5f",newLocation.coordinate.longitude]];
	[altLabel setStringValue:[NSString stringWithFormat:@"%4.2f",newLocation.altitude]];
}



@end
