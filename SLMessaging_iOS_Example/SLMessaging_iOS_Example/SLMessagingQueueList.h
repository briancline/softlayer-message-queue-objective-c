//
//  SLMessagingAccountViewController.h
//  SLMessaging_iOS_Example
//
//  Created by SLDN on 10/2/12.
//  Copyright (c) 2012 SoftLayer Technologies, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SLMessagingQueue;

@interface SLMessagingQueueList : UITableViewController
@property (weak, nonatomic) SLMessagingQueue *selectedQueue;
@end
