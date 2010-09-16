//
//  APAgentAppDelegate.h
//  APAgent
//
//  Created by Lvsti on 2010.09.15..
//

#import <UIKit/UIKit.h>

@class APAgentViewController;

@interface APAgentAppDelegate : NSObject <UIApplicationDelegate>
{
    UIWindow *window;
    APAgentViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet APAgentViewController *viewController;

@end

