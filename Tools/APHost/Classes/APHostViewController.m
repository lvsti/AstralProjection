//
//  APHostViewController.m
//  APHost
//
//  Created by Lvsti on 2010.09.16..
//

#import "APHostViewController.h"
#import "APGPXDataSource.h"
#import "APLocationManager.h"


@implementation APHostViewController


- (id)initWithCoder:(NSCoder*)aDecoder
{
	if ( (self = [super initWithCoder:aDecoder]) )
	{
		locationManager = [[APLocationManager alloc] init];
		
		gpxDataSource = [[APGPXDataSource alloc] initWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ashland" ofType:@"gpx"]]];
		if ( [gpxDataSource cardinalityForDataSet:kAPGPXDataSetTrack] > 7 )
		{
			[gpxDataSource setActiveDataSet:kAPGPXDataSetTrack subsetIndex:7];
		}
		
		gpxDataSource.locationDataDelegate = (APLocationManager*)locationManager;
		gpxDataSource.timeScale = 30.0;
		
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
	[gpxDataSource stopGeneratingLocationEvents];
	[gpxDataSource release];
	
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
		[gpxDataSource startGeneratingLocationEvents];
	}
	else
	{
		[toggleUpdatesButton setTitle:@"Start" forState:UIControlStateNormal];
		[gpxDataSource stopGeneratingLocationEvents];
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

@end
