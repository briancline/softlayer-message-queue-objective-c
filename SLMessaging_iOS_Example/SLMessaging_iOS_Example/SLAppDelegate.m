//
//  SLAppDelegate.m
//  SLMessaging_iOS_Example
//
//  Created by SLDN on 9/11/12.
//  Copyright (c) 2012 SoftLayer Technologies, Inc. All rights reserved.
//


#import "SLAppDelegate.h"
#import "SLMessagingQueueList.h"
#import "SLMessageQueueDetailViewController.h"

static char * const kSelectedMessagingQueueChanged = "SelectedMessagingQueueChanged";

@interface SLAppDelegate ()
@property (weak, nonatomic) IBOutlet SLMessagingQueueList *messageQueueListController;
@property (weak, nonatomic) IBOutlet SLMessageQueueDetailViewController *messageQueueDetailController;
@property (weak) UIPopoverController *popoverController;
@end

@implementation SLAppDelegate

- (BOOL) application: (UIApplication *)application didFinishLaunchingWithOptions: (NSDictionary *) launchOptions
{
	self.window.rootViewController = self.mainSplitViewController;

	[_messageQueueListController addObserver: self
								  forKeyPath: @"selectedQueue"
									 options: 0
									 context: kSelectedMessagingQueueChanged];

	[self.window makeKeyAndVisible];

	return YES;
}

- (void) observeValueForKeyPath: (NSString *) keyPath
					   ofObject: (id) object
						 change: (NSDictionary *) change
						context: (void *) context
{
    if (context == kSelectedMessagingQueueChanged) {
		_messageQueueDetailController.messagingQueue = _messageQueueListController.selectedQueue;
		[self.popoverController dismissPopoverAnimated: YES];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - UISplitViewControllerDelegate


- (void) splitViewController: (UISplitViewController *) svc
	  willHideViewController: (UIViewController *) aViewController
		   withBarButtonItem: (UIBarButtonItem *) barButtonItem
		forPopoverController:(UIPopoverController *)pc
{
	barButtonItem.title = @"Queues";
	self.messageQueueDetailController.toolbar.items = @[barButtonItem];
	_popoverController = pc;
}

// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void) splitViewController: (UISplitViewController *) svc
	  willShowViewController: (UIViewController *) aViewController
   invalidatingBarButtonItem: (UIBarButtonItem *) barButtonItem
{
	self.messageQueueDetailController.toolbar.items = @[];
	_popoverController = nil;
}
@end
