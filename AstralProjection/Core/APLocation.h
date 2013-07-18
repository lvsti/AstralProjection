//
//  APLocation.h
//  AstralProjection
//
//  Created by Lkxf on 2010.10.10..
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>


@interface APLocation : CLLocation

#define APLOCATION_PROPERTY_ATOMICITY NS_NONATOMIC_IPHONEONLY

#if !TARGET_OS_IPHONE

#if __MAC_OS_X_VERSION_MAX_ALLOWED > __MAC_10_6
// OSX 10.7 apparently dropped the macro and sets the property unconditionally to nonatomic
#undef APLOCATION_PROPERTY_ATOMICITY
#define APLOCATION_PROPERTY_ATOMICITY nonatomic
#else
@property (readonly, APLOCATION_PROPERTY_ATOMICITY) CLLocationSpeed speed;
@property (readonly, APLOCATION_PROPERTY_ATOMICITY) CLLocationDirection course;
#endif

- (id)initWithCoordinate:(CLLocationCoordinate2D)aCoordinate
				altitude:(CLLocationDistance)aAltitude
	  horizontalAccuracy:(CLLocationAccuracy)aHAccuracy
		verticalAccuracy:(CLLocationAccuracy)aVAccuracy
				  course:(CLLocationDirection)aCourse
				   speed:(CLLocationSpeed)aSpeed
			   timestamp:(NSDate*)aTimestamp;

#endif

@property (retain, APLOCATION_PROPERTY_ATOMICITY) NSDate* timestamp;
#undef APLOCATION_PROPERTY_ATOMICITY


@end
