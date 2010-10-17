//
//  APHostViewController.m
//  APHost
//
//  Created by Lvsti on 2010.09.16..
//

#import "APHostViewController.h"
#import "APGPXDataSource.h"
#import "APAgentDataSource.h"
#import "APLocationManager.h"


// enable agent here
#define AGENT_DATASOURCE


@implementation APHostViewController


- (id)initWithCoder:(NSCoder*)aDecoder
{
	if ( (self = [super initWithCoder:aDecoder]) )
	{
		locationManager = [[APLocationManager alloc] init];

#if defined(AGENT_DATASOURCE)
		APAgentDataSource* agent = [[APAgentDataSource alloc] init];
		locationDataSource = agent;
#else
		APGPXDataSource* gpx = [[APGPXDataSource alloc] initWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ashland" ofType:@"gpx"]]];
		if ( [gpx cardinalityForDataSet:kAPGPXDataSetTrack] > 7 )
		{
			[gpx setActiveDataSet:kAPGPXDataSetTrack subsetIndex:7];
		}

		locationDataSource = gpx;
#endif
		locationDataSource.locationDataDelegate = (APLocationManager*)locationManager;
		
		// you need to skip this check on the simulator
#ifndef TARGET_IPHONE_SIMULATOR
		if ( [CLLocationManager locationServicesEnabled] )
		{
#endif			
			locationManager.delegate = self;
#ifndef TARGET_IPHONE_SIMULATOR			
		}
#endif
    }
    return self;
}


- (void)dealloc
{
	[locationDataSource stopGeneratingLocationEvents];
	[locationDataSource release];
	
	[locationManager stopUpdatingLocation];
	[locationManager release];
	
    [super dealloc];
}


- (IBAction)toggleLocationUpdates
{
	if ( !isUpdatingLocation )
	{
		[toggleUpdatesButton setTitle:@"Stop" forState:UIControlStateNormal];
		[locationManager startUpdatingLocation];
		[locationDataSource startGeneratingLocationEvents];
	}
	else
	{
		[toggleUpdatesButton setTitle:@"Start" forState:UIControlStateNormal];
		[locationDataSource stopGeneratingLocationEvents];
		[locationManager stopUpdatingLocation];
	}
	
	isUpdatingLocation = !isUpdatingLocation;
}


#pragma mark -
#pragma mark from CLLocationManagerDelegate:

- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation
{
	latitude.text = [NSString stringWithFormat:@"%3.5f",newLocation.coordinate.latitude];
	longitude.text = [NSString stringWithFormat:@"%3.5f",newLocation.coordinate.longitude];
}


- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error
{
}


- (void)locationManager:(CLLocationManager *)manager
	   didUpdateHeading:(CLHeading *)newHeading
{
	heading.text = [NSString stringWithFormat:@"%3.2f",newHeading.magneticHeading];
}

@end
