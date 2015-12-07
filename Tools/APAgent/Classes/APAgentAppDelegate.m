//
//  APAgentAppDelegate.m
//  APAgent
//
//  Created by Lvsti on 2010.09.15..
//

#import "APAgentAppDelegate.h"
#import "APAgentViewController.h"

@interface APAgentAppDelegate ()
@property (nonatomic, strong) IBOutlet APAgentViewController *viewController;
@end

@implementation APAgentAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self.window addSubview:self.viewController.view];
    [self.window makeKeyAndVisible];

    return YES;
}

@end
