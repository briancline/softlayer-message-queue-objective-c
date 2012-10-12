//
//  SLMessagingAccountViewController.m
//  SLMessaging_iOS_Example
//
//  Created by SLDN on 10/2/12.
//  Copyright (c) 2012 SoftLayer Technologies, Inc. All rights reserved.
//

#import <SoftLayerMessaging/SoftLayerMessaging.h>

#import "SLMessagingQueueList.h"
#import "SLMessageQueueDetailViewController.h"

#warning Replace the following constants with your messaging account, SoftLayer user name, and API key
static NSString * const kMessagingAccountName = @"messaging account here";
static NSString * const kSoftLayerAccountUserName = @"softlayer user name here";
static NSString * const kSoftLayerAccountAPIKey = @" api key here";

static NSString * const kMessagingAccountViewCellID = @"MessagingAccountViewCellID";

@interface SLMessagingQueueList ()
@property (strong, nonatomic) SLMessagingClient *messagingClient;
@property (strong, nonatomic) NSArray *messageQueues;
@property (strong, nonatomic) id<SLCancelableOperation> currentRequest;

@property (weak, nonatomic) UIBarButtonItem *refreshButton;
@end

@implementation SLMessagingQueueList

- (void) awakeFromNib
{
	_messagingClient = [[SLMessagingClient alloc] initWithMessagingAccount: kMessagingAccountName
																   options: @{ SLMessagingClientOption_ResourceBaseURL : [NSURL URLWithString: @"https://dal05.mq.softlayer.net"]} ];
	self.messageQueues = @[];

	[self.tableView registerClass: [UITableViewCell class] forCellReuseIdentifier: kMessagingAccountViewCellID];
}

- (void) viewWillAppear: (BOOL) animated
{
	[super viewWillAppear: animated];
	if(![self.messagingClient isAuthenticated])
	{
		[_messagingClient authenticateWithUsername: kSoftLayerAccountUserName
											apiKey: kSoftLayerAccountAPIKey
											 queue: [NSOperationQueue mainQueue]
								 completionHandler: ^(SLMessagingClient *client, BOOL success, NSError *error)
		 {
			 if(success && nil == error)
			 {
				 [self refreshQueueList: self];
			 } else {
				 UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Authentication Failed"
																 message: @"The application could not validate the messaging account and the queue list could not be obtained"
																delegate: nil
													   cancelButtonTitle: @"OK"
													   otherButtonTitles: nil];
				 [alert show];
			 }
		 }];
	}

	[[self navigationController] setToolbarHidden: NO animated: animated];
}

- (void) refreshQueueList: (id) sender
{
	if(!_currentRequest)
	{
		self.refreshButton.enabled = NO;
		self.currentRequest = [_messagingClient requestMessagingQueuesWithTags: nil
																		 queue: [NSOperationQueue mainQueue]
															 completionHandler:^(SLMessagingClient *client, NSArray *messagingQueues, NSError *error) {
																 self.currentRequest = nil;
																 self.refreshButton.enabled = YES;
																 self.messageQueues = messagingQueues;
															 }];
	}
}

- (void) setMessageQueues: (NSArray *) messageQueues
{
	_messageQueues = messageQueues;
	[self.tableView reloadData];
}

- (void) viewDidLoad
{
	[super viewDidLoad];

	UIBarButtonItem *refreshToolbarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemRefresh target: self action: @selector(refreshQueueList:)];

	self.navigationItem.title = kMessagingAccountName;
	self.toolbarItems = @[refreshToolbarButton];
	self.refreshButton = refreshToolbarButton;

	self.hidesBottomBarWhenPushed = NO;
}

- (void) didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (SLMessagingQueue *) messagingQueueForIndexPath: (NSIndexPath *) indexPath
{
	NSAssert(indexPath.row < [self.messageQueues count], nil);
	return [self.messageQueues objectAtIndex: indexPath.row];
}

#pragma mark - UITableViewDataSource

- (NSInteger) tableView: (UITableView *) tableView
  numberOfRowsInSection: (NSInteger) section
{
	return [self.messageQueues count];
}

- (UITableViewCell *) tableView: (UITableView *) tableView
		  cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier: kMessagingAccountViewCellID];

	SLMessagingQueue *messagingQueue = [self messagingQueueForIndexPath: indexPath];

	cell.textLabel.text = messagingQueue.name;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

	return cell;
}

#pragma mark - UITableViewDelegate

- (void)       tableView: (UITableView *) tableView
 didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
	self.selectedQueue = [self messagingQueueForIndexPath: indexPath];
}

@end
