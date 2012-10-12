//
//  SLAppDelegate.h
//  SoftLayerMessaging_MacOSX_Example
//
//  Created by SLDN on 10/9/12.
//  Copyright (c) 2012 SoftLayer Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SLMessagingAccountBrowser.h"

@interface SLAppDelegate : NSObject <NSApplicationDelegate>
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet SLMessagingAccountBrowser *accountBrowser;
@end
