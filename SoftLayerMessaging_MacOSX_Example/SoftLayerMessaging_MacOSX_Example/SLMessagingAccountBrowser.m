//
//  SLMessagingAccountBrowser.m
//  SoftLayerMessaging_MacOSX_Example
//
//  Created by SLDN on 10/9/12.
//  Copyright (c) 2012 SoftLayer Technologies, Inc. All rights reserved.
//

#import <SoftLayerMessaging/SoftLayerMessaging.h>
#import "SLMessagingAccountBrowser.h"
#import <objc/runtime.h>

#warning Replace the following constants with your messaging account, SoftLayer user name, and API key
static NSString * const kMessagingAccountName = @"messaging account here";
static NSString * const kSoftLayerAccountUserName = @"softlayer user name here";
static NSString * const kSoftLayerAccountAPIKey = @" api key here";

@interface SLMessagingAccountBrowser ()
@property (assign) IBOutlet NSTreeController *queueListController;
@property (assign) IBOutlet NSArrayController *latestMessages;
@property (assign) NSArray *messagingQueues;

@property (strong, nonatomic) SLMessagingClient *messagingClient;
@property (strong, nonatomic) id <SLCancelableOperation> currentRequest;
@property (weak) IBOutlet NSOutlineView *outlineView;
@property (weak) IBOutlet NSTextField *postMessageTextField;
@property (copy) NSString *postMessageStatus;

@property (copy) NSString *retrieveMessagesStatus;
@property (strong, nonatomic) NSDate *messagesRetrievedDate;
@end

/* Messaging queues don't really have children, but the tree controller wants
 to know what method to call to find them.  So we provide a method */
@interface SLMessagingQueue (sl_make_tree_controller_happy)
- (NSArray *) children;
@end

@implementation SLMessagingAccountBrowser

- (id) init
{
	self = [super init];
	if(self)
	{
		_messagingClient = [[SLMessagingClient alloc] initWithMessagingAccount: kMessagingAccountName
																	   options: @{ SLMessagingClientOption_ResourceBaseURL : [NSURL URLWithString: @"https://dal05.mq.softlayer.net"]} ];
		self.messagingQueues = @[];
		self.postMessageStatus = @"";
		self.retrieveMessagesStatus = @"";
	}

	return self;
}

- (void) awakeFromNib
{
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
				 NSAlert *alert = [NSAlert alertWithMessageText: @"Authentication Failed"
												  defaultButton: @"OK"
												alternateButton: nil
													otherButton: nil
									  informativeTextWithFormat: @"The application could not validate the messaging account and the queue list could not be obtained"];
				 [alert runModal];
			 }
		 }];
	}

	[self updateMessagesStatusText];
}

- (void) refreshQueueList: (id) sender
{
	if(!_currentRequest)
	{
		self.currentRequest = [_messagingClient requestMessagingQueuesWithTags: nil
																		 queue: [NSOperationQueue mainQueue]
															 completionHandler:^(SLMessagingClient *client, NSArray *messagingQueues, NSError *error) {
																 self.currentRequest = nil;
																 self.messagingQueues = messagingQueues;
															 }];
	}
}

- (void) setMessagesRetrievedDate: (NSDate *) newDate
{
	_messagesRetrievedDate = newDate;

	[self updateMessagesStatusText];
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

		if(0 == [self.latestMessages.arrangedObjects count])
		{
			statusText = [statusText stringByAppendingString: @" -- No visible messages were found"];
		}

		self.retrieveMessagesStatus = statusText;
	} else {
		self.retrieveMessagesStatus = @"Tap 'Retrieve Messages' to get the latest messages in this queue";
	}
}

- (IBAction) postMessage:(id)sender
{
	NSString *messageString = [_postMessageTextField stringValue];
	if(messageString && messageString.length > 0)
	{
		if(nil == _currentRequest)
		{
			self.postMessageStatus = @"Posting…";
			self.currentRequest = [self.queueListController.selectedObjects[0] publishMessage: messageString
																				   withFields: nil
																						queue: [NSOperationQueue mainQueue]
																			completionHandler:^(SLMessagingQueue *queue, SLMessagingMessage *postedMessage, NSError *error) {
																				self.currentRequest = nil;

																				if(!error)
																				{
																					self.postMessageStatus = @"Message Posted";
																					_postMessageTextField.stringValue = @"";
																				} else {
																					NSLog(@"%@", error);
																					NSAlert *alert = [NSAlert alertWithMessageText: @"Post Failed"
																													 defaultButton: @"OK"
																												   alternateButton: nil
																													   otherButton: nil
																										 informativeTextWithFormat: @"The application could not post your message to the queue"];
																					[alert runModal];

																					self.postMessageStatus = @"Post failed";
																				}
																			}];
		}
	} else {
		NSAlert *alert = [NSAlert alertWithMessageText: @"Empty Message"
										 defaultButton: @"OK"
									   alternateButton: nil
										   otherButton: nil
							 informativeTextWithFormat: @"The message text cannot be empty"];
		[alert runModal];
	}
}

- (IBAction) refreshMessageQueueDetails: (id) sender
{
	if(!_currentRequest)
	{
		self.currentRequest = [self.queueListController.selectedObjects[0] retrievePropertiesWithQueue: [NSOperationQueue mainQueue]
																					 completionHandler: ^(SLMessagingQueue *queue, NSError *error)
							   {
								   self.currentRequest = nil;
								   if(error)
								   {
									   NSLog(@"%@", error);
								   }
							   }];
	}
}


- (IBAction) retrieveMessages: (id) sender
{
	if(!self.currentRequest)
	{
		self.currentRequest = [self.queueListController.selectedObjects[0] requestMessagesWithLimit: 50
																							  queue: [NSOperationQueue mainQueue]
																				  completionHandler: ^(SLMessagingQueue *messagingQueue, NSArray *visibleMessages, NSError *error)
							   {
								   self.currentRequest = nil;

								   if(nil != visibleMessages)
								   {
									   self.latestMessages.content = visibleMessages;
									   [self setMessagesRetrievedDate: [NSDate date]];
								   } else {
									   NSLog(@"%@", error);

									   NSAlert *alert = [NSAlert alertWithMessageText: @"Retrieve Failed"
																		defaultButton: @"OK"
																	  alternateButton: nil
																		  otherButton: nil
															informativeTextWithFormat: @"Could not retrieve a list of messages from the server."];
									   [alert runModal];

									   self.retrieveMessagesStatus = @"An Error prevented the list of messages from being retrieved.";
								   }
							   }];
	}
}

@end

@implementation SLMessagingQueue (sl_make_tree_controller_happy)
- (NSArray *) children
{
	return @[];
}
@end
