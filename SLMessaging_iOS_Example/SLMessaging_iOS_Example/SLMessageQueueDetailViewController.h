//
//  SLMessageQueueDetailViewController.h
//  SLMessaging_iOS_Example
//
//  Created by SLDN on 10/2/12.
//  Copyright (c) 2012 SoftLayer Technologies, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SLMessagingQueue;

@interface SLMessageQueueDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) SLMessagingQueue *messagingQueue;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@end
