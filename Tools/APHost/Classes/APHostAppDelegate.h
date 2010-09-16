//
//  APHostAppDelegate.h
//  APHost
//
//  Created by Lvsti on 2010.09.16..
//

#import <UIKit/UIKit.h>

@class APHostViewController;

@interface APHostAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    APHostViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet APHostViewController *viewController;

@end

