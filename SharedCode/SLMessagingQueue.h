//
//  SLMessagingQueue.h
//  SLMessaging
//
//  Created by SLDN on 9/12/12.
//  Copyright (c) 2012 SoftLayer Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SoftLayerMessaging/SLCancelableOperation.h>

@class SLMessagingClient;
@class SLJSONRestResource;
@class SLMessagingMessage;

@interface SLMessagingQueue : NSObject

@property (strong, readonly, nonatomic) SLMessagingClient *messagingClient;

@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) NSArray *tags;
@property (readonly, nonatomic) NSUInteger messageCount;
@property (readonly, nonatomic) NSUInteger visibleMessageCount;
@property (readonly, nonatomic) NSTimeInterval visibilityInterval;
@property (readonly, nonatomic) NSTimeInterval expirationInterval;

@property (strong, readonly, nonatomic) NSDictionary *jsonRepresentation;

- (id) initWithRestResource: (SLJSONRestResource *) restResource
				 properties: (NSDictionary *) properties;


/*!
 Send a network request to update the properties of this Queue so that they
 match the server's latest information on the Queue
 */
- (id<SLCancelableOperation>) retrievePropertiesWithQueue: (NSOperationQueue *) completionQueue
										completionHandler: (void (^)(SLMessagingQueue *queue, NSError *error)) completionHandler;

/*!
 Send a network request to change the properties of this Queue on the server
 */
- (id<SLCancelableOperation>) updateProperties: (NSDictionary *) properties
										 queue: (NSOperationQueue *) completionQueue
							 completionHandler: (void (^)(SLMessagingQueue *queue, NSError *error)) completionHandler;

/*!
 Delete the queue permanetly from the account.
 */
- (id<SLCancelableOperation>) deleteMessagingQueue: (BOOL) forceDelete
											 queue: (NSOperationQueue *) completionQueue
								 completionHandler: (void (^)(BOOL succeeded, NSError *error)) completionHandler;

/*!
 Place a new message into the message queue.
 */
- (id<SLCancelableOperation>) publishMessage: (NSString *) message
								  withFields: (NSDictionary *) additionalFieldsOrNil
									   queue: (NSOperationQueue *) completionQueue
						   completionHandler: (void (^)(SLMessagingQueue *queue, SLMessagingMessage *postedMessage, NSError *error)) completionHandler;

/*!
 Retrieve visible messages from the queue and return them
 */
- (id<SLCancelableOperation>) requestMessagesWithLimit: (NSUInteger) numberToRetrieve
												 queue: (NSOperationQueue *) completionQueue
									 completionHandler: (void (^)(SLMessagingQueue *queue, NSArray *visibleMessages, NSError *error)) completionHandler;

/*!
 Delete the message with the given ID from the queue.
 */
- (id<SLCancelableOperation>) deleteMessageWithID: (NSString *) messageID
											queue: (NSOperationQueue *) completionQueue
								completionHandler: (void (^)(BOOL succeeded, NSError *error)) completionHandler;
@end

/* Message queue properties */
extern NSString * const kMessagingQueue_TagsProperty;
extern NSString * const kMessagingQueue_VisibiltyIntervalProperty;
extern NSString * const kMessagingQueue_ExpirationIntervalProperty;