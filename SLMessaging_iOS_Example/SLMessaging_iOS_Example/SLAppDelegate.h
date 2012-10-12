//
//  SLAppDelegate.h
//  SLMessaging_iOS_Example
//
//  Created by SLDN on 9/11/12.
//  Copyright (c) 2012 SoftLayer Technologies, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SLAppDelegate : UIResponder <UIApplicationDelegate, UISplitViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UIWindow *window;
@property (strong, nonatomic) IBOutlet UISplitViewController *mainSplitViewController;

@end
