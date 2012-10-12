//
//  SLMessageQueueDetailViewController.m
//  SLMessaging_iOS_Example
//
//  Created by SLDN on 10/2/12.
//  Copyright (c) 2012 SoftLayer Technologies, Inc. All rights reserved.
//

#import <SoftLayerMessaging/SoftLayerMessaging.h>
#import <QuartzCore/QuartzCore.h>

#import "SLMessageQueueDetailViewController.h"

NSString * const kQueueTagTableCellID = @"QueueTagTableCellID";
NSString * const kQueueMessagesTableCellID = @"QueueMessagesTableCellID";

@interface SLMessageQueueDetailViewController ()
@property (strong, nonatomic) NSArray *latestMessages;
@property (strong, nonatomic) NSDate *messagesRetrievedDate;
@property (strong, nonatomic) id<SLCancelableOperation> currentRequest;

@property (weak, nonatomic) IBOutlet UIButton *retrieveMessagesButton;
@property (weak, nonatomic) IBOutlet UILabel *messageCountValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *visibileCountValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *visibilityIntervalValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *expirationIntervalValueLabel;
@property (weak, nonatomic) IBOutlet UITableView *tagTableView;
@property (weak, nonatomic) IBOutlet UITableView *messagesTableView;
@property (weak, nonatomic) IBOutlet UILabel *messagesTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *messagesStatusLabel;
@property (weak, nonatomic) IBOutlet UITextField *postMessageTextField;
@property (weak, nonatomic) IBOutlet UIButton *postMessageButton;
@property (weak, nonatomic) IBOutlet UILabel *postMessageStatusLabel;
@end

@implementation SLMessageQueueDetailViewController

- (void) awakeFromNib
{
	self.messagingQueue = nil;
	self.latestMessages = @[];
}

- (void) setMessagingQueue:(SLMessagingQueue *)messagingQueue
{
	_messagingQueue = messagingQueue;
	self.latestMessages = @[];

	[self updateQueueDetailFields];
	[self setMessagesRetrievedDate: nil];

	[self.messagesTableView reloadData];
	[self.tagTableView reloadData];
}

- (void) viewDidLoad
{
    [super viewDidLoad];

	UIBarButtonItem *refreshToolbarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemRefresh target: self action: @selector(refreshMessageQueueDetails:)];

	self.navigationItem.title = self.messagingQueue.name;
	self.toolbarItems = @[refreshToolbarButton];

	self.messageCountValueLabel.text = @"";
	self.visibileCountValueLabel.text = @"";
	self.visibilityIntervalValueLabel.text = @"";
	self.expirationIntervalValueLabel.text = @"";

	[self.tagTableView registerClass: [UITableViewCell class] forCellReuseIdentifier: kQueueTagTableCellID];

	self.tagTableView.layer.borderWidth = 1.0;
	self.tagTableView.layer.borderColor = [[UIColor lightGrayColor] CGColor];

	NSLayoutConstraint *tableViewOffFromCenter = [NSLayoutConstraint constraintWithItem: self.tagTableView
																			  attribute: NSLayoutAttributeBottom
																			  relatedBy: NSLayoutRelationEqual
																				 toItem: self.view
																			  attribute: NSLayoutAttributeCenterY
																			 multiplier: 1.0
																			   constant: -8];
	[self.view addConstraint: tableViewOffFromCenter];

	NSLayoutConstraint *centerToMessagesTitle = [NSLayoutConstraint constraintWithItem: self.messagesTitleLabel
																			 attribute: NSLayoutAttributeTop
																			 relatedBy: NSLayoutRelationEqual
																				toItem: self.view
																			 attribute: NSLayoutAttributeCenterY
																			multiplier: 1.0
																			  constant: 8];
	[self.view addConstraint: centerToMessagesTitle];

	self.messagesTableView.layer.borderWidth = 1.0;
	self.messagesTableView.layer.borderColor = [[UIColor lightGrayColor] CGColor];

}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) viewWillAppear: (BOOL) animated
{
	[super viewWillAppear: animated];

	[self updateQueueDetailFields];
	[self updateMessagesStatusText];
}

- (void) viewDidUnload
{
	[self setMessageCountValueLabel: nil];
	[self setVisibileCountValueLabel: nil];
	[self setVisibilityIntervalValueLabel: nil];
	[self setExpirationIntervalValueLabel: nil];
	[self setTagTableView:nil];
	[self setMessagesTableView:nil];
	[self setMessagesTitleLabel:nil];
	[self setMessagesStatusLabel:nil];
	[self setRetrieveMessagesButton:nil];
	[self setPostMessageTextField:nil];
	[self setPostMessageButton:nil];
	[self setPostMessageStatusLabel:nil];
	[super viewDidUnload];
}

- (void) setCurrentRequest:(id<SLCancelableOperation>)currentRequest
{
	_currentRequest = currentRequest;

	if(_currentRequest)
	{
		self.retrieveMessagesButton.enabled = NO;
		self.postMessageButton.enabled = NO;
	} else {
		self.retrieveMessagesButton.enabled = YES;
		self.postMessageButton.enabled = YES;
	}
}

- (IBAction) refreshMessageQueueDetails: (id) sender
{
	if(!_currentRequest)
	{
		self.currentRequest = [self.messagingQueue retrievePropertiesWithQueue: [NSOperationQueue mainQueue]
															 completionHandler: ^(SLMessagingQueue *queue, NSError *error)
							   {
								   self.currentRequest = nil;

								   [self updateQueueDetailFields];

								   if(error)
								   {
									   NSLog(@"%@", error);
								   }
							   }];
	}
}

- (IBAction) postNewMessage: (id) sender
{
	NSString *messageString = [self.postMessageTextField text];

	if(messageString && messageString.length > 0)
	{
		if(nil == _currentRequest)
		{
			self.postMessageStatusLabel.text = @"Posting…";

			self.currentRequest = [self.messagingQueue publishMessage: messageString
														   withFields: nil
																queue: [NSOperationQueue mainQueue]
													completionHandler:^(SLMessagingQueue *queue, SLMessagingMessage *postedMessage, NSError *error) {
														self.currentRequest = nil;

														if(!error)
														{
															self.postMessageStatusLabel.text = @"Message Posted";
															self.postMessageTextField.text = @"";
														} else {
															NSLog(@"%@", error);

															UIAlertView *postFailed = [[UIAlertView alloc] initWithTitle: @"Post Failed"
																												 message: @"An error occurred while posting your message"
																												delegate: nil
																									   cancelButtonTitle: @"OK"
																									   otherButtonTitles: nil];
															[postFailed show];
															self.postMessageStatusLabel.text = @"Post failed";
														}
													}];
		}
	} else {
		UIAlertView *emptyMessageAlert = [[UIAlertView alloc] initWithTitle: @"Empty Message"
																	message: @"The message text cannot be empty"
																   delegate: nil
														  cancelButtonTitle: @"OK"
														  otherButtonTitles: nil];
		[emptyMessageAlert show];
	}
}

- (IBAction) retrieveMessages: (id) sender
{
	if(!self.currentRequest)
	{
		self.currentRequest = [self.messagingQueue requestMessagesWithLimit: 50
																	  queue: [NSOperationQueue mainQueue]
														  completionHandler: ^(SLMessagingQueue *messagingQueue, NSArray *visibleMessages, NSError *error)
							   {
								   self.currentRequest = nil;

								   if(nil != visibleMessages)
								   {
									   self.latestMessages = visibleMessages;
									   [self setMessagesRetrievedDate: [NSDate date]];
									   [[self messagesTableView] reloadData];
								   } else {
									   NSLog(@"%@", error);

									   UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Retrieve Failed"
																					   message: @"Could not retrieve a list of messages from the server."
																					  delegate: nil
																			 cancelButtonTitle: @"OK"
																			 otherButtonTitles: nil];
									   [alert show];

									   self.messagesStatusLabel.text = @"An Error prevented the list of messages from being retrieved.";
								   }
							   }];
	}
}

- (void) setMessagesRetrievedDate: (NSDate *) newDate
{
	_messagesRetrievedDate = newDate;

	[self updateMessagesStatusText];
}

- (void) updateQueueDetailFields
{
	self.messageCountValueLabel.text = [NSString stringWithFormat: @"%d", self.messagingQueue.messageCount];
	self.visibileCountValueLabel.text = [NSString stringWithFormat: @"%d", self.messagingQueue.visibleMessageCount];
	self.visibilityIntervalValueLabel.text = [NSString stringWithFormat: @"%d", (int) self.messagingQueue.visibilityInterval];
	self.expirationIntervalValueLabel.text = [NSString stringWithFormat: @"%d", (int) self.messagingQueue.expirationInterval];

	[self.tagTableView reloadData];
}

- (void) updateMessagesStatusText
{
	if(_messagesRetrievedDate)
	{
		static NSDateFormatter *dateFormatter;

		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateStyle: kCFDateFormatterMediumStyle];
			[dateFormatter setTimeStyle: kCFDateFormatterMediumStyle];
		});

		NSString *formattedDate = [dateFormatter stringFromDate: _messagesRetrievedDate];
		NSString *statusText = [NSString stringWithFormat: @"Messages last retrieved %@", formattedDate];

		if(0 == [self.latestMessages count])
		{
			statusText = [statusText stringByAppendingString: @" -- No visible messages were found"];
		}

		self.messagesStatusLabel.text = statusText;
	} else {
		self.messagesStatusLabel.text = @"Tap 'Retrieve Messages' to get the latest messages in this queue";
	}
}

- (SLMessagingMessage *) messageAtIndexPath: (NSIndexPath *) indexPath
{
	return [self.latestMessages objectAtIndex: indexPath.row];
}

#pragma mark - UITableViewDataSource

- (NSInteger) tableView: (UITableView *) tableView
  numberOfRowsInSection: (NSInteger) section
{
	NSInteger numberOfRows = 0;

	if(tableView == self.tagTableView)
	{
		numberOfRows = [self.messagingQueue.tags count];
	}

	if(tableView == self.messagesTableView)
	{
		numberOfRows = [self.latestMessages count];
	}

	return numberOfRows;
}

- (UITableViewCell *) tagTableView: (UITableView *) tableView
			 cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: kQueueTagTableCellID];

	cell.textLabel.text = [[self.messagingQueue tags] objectAtIndex: indexPath.row];
	cell.textLabel.adjustsFontSizeToFitWidth = YES;
	cell.textLabel.minimumScaleFactor = 0.25;

	return cell;
}

- (UITableViewCell *) messagesTableView: (UITableView *) tableView
				  cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: kQueueMessagesTableCellID];

	if(nil == cell)
	{
		cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleSubtitle reuseIdentifier: kQueueMessagesTableCellID];
	}

	SLMessagingMessage *message = [self messageAtIndexPath: indexPath];

	cell.textLabel.text = message.body;
	cell.detailTextLabel.text = message.messageID;
	cell.textLabel.adjustsFontSizeToFitWidth = YES;
	cell.textLabel.minimumScaleFactor = 0.25;

	return cell;
}

- (UITableViewCell *) tableView: (UITableView *) tableView
		  cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
	UITableViewCell *cell = nil;

	if(tableView == self.tagTableView)
	{
		cell = [self tagTableView: tableView cellForRowAtIndexPath: indexPath];
	}

	if(tableView == self.messagesTableView)
	{
		cell = [self messagesTableView: tableView cellForRowAtIndexPath: indexPath];
	}

	return cell;
}

- (void)     tableView: (UITableView *) tableView
	commitEditingStyle: (UITableViewCellEditingStyle) editingStyle
	 forRowAtIndexPath: (NSIndexPath *) indexPath
{
	if(tableView == self.messagesTableView && editingStyle == UITableViewCellEditingStyleDelete)
	{
		if(nil == _currentRequest)
		{
			SLMessagingMessage *messageToDelete = [self messageAtIndexPath: indexPath];
			self.currentRequest = [messageToDelete deleteMessageWithQueue: [NSOperationQueue mainQueue]
														completionHandler: ^(BOOL succeeded, NSError *error) {
															if(!error)
															{
																self.latestMessages = [self.latestMessages arrayWithElementsPassingTest:^BOOL(SLMessagingMessage *message, NSUInteger idx) {
																	return message != messageToDelete;
																}];

																[tableView deleteRowsAtIndexPaths: @[indexPath] withRowAnimation: UITableViewRowAnimationFade];

																self.currentRequest = nil;
															} else {
																NSLog(@"%@", error);

																UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Delete Failed"
																												message: @"Could not delete the message from the server."
																											   delegate: nil
																									  cancelButtonTitle: @"OK"
																									  otherButtonTitles: nil];
																[alert show];
															}
														}];
		}
	}
}

#pragma mark - UITableViewDelegate

- (NSIndexPath *) tableView: (UITableView *) tableView
   willSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
	return nil;
}

- (BOOL)                tableView: (UITableView *) tableView
	shouldHighlightRowAtIndexPath: (NSIndexPath *) indexPath
{
	return NO;
}

- (UITableViewCellEditingStyle) tableView: (UITableView *) tableView
			editingStyleForRowAtIndexPath: (NSIndexPath *) indexPath
{
	UITableViewCellEditingStyle editingStyle = UITableViewCellEditingStyleNone;
	if(tableView == self.messagesTableView)
	{
		return UITableViewCellEditingStyleDelete;
	}
	
	return editingStyle;
}
@end
