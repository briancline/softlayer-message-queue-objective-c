//
//  SLMessagingTopic.h
//  SLMessaging_iOS
//
//  Created by SLDN on 9/14/12.
//  Copyright (c) 2012 SoftLayer Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SoftLayerMessaging/SLCancelableOperation.h>

@class SLJSONRestResource;
@class SLMessagingSubscription;

@interface SLMessagingTopic : NSObject

@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) NSArray *tags;

- (id) initWithRestResource: (SLJSONRestResource *) restResource
				 properties: (NSDictionary *) properties;

/*!
 Send a network request to update the properties of this Topic so that they
 match the server's latest information on the Topic
 */
- (id<SLCancelableOperation>) retrievePropertiesWithQueue: (NSOperationQueue *) completionQueue
										completionHandler: (void (^)(SLMessagingTopic *topic, NSError *error)) completionHandler;

/*!
 Send a network request to change the properties of this Topic on the server
 */
- (id<SLCancelableOperation>) updateProperties: (NSDictionary *) properties
										 queue: (NSOperationQueue *) completionQueue
							 completionHandler: (void (^)(SLMessagingTopic *queue, NSError *error)) completionHandler;

/*!
 Delete this Topic permanentsly from the account.
 */
- (id<SLCancelableOperation>) deleteTopic: (BOOL) forceDelete
									queue: (NSOperationQueue *) completionQueue
						completionHandler: (void (^)(BOOL succeeded, NSError *error)) completionHandler;

/*!
 Publish a new message to the topic
 */
- (id<SLCancelableOperation>) publishMessage: (NSString *) message
									withTags: (NSArray *) tags
									   queue: (NSOperationQueue *) completionQueue
						   completionHandler: (void (^)(SLMessagingTopic *topic, SLMessagingMessage *publishedMessage, NSError *error)) completionHandler;

/*!
 Request information about the subscribers to this topic.
 */

- (id<SLCancelableOperation>) requestSubscriptionsWithQueue: (NSOperationQueue *) completionQueue
										  completionHandler: (void (^)(SLMessagingTopic *topic, NSArray *subscriptions, NSError *error)) completionHandler;

/*!
 Subscribe to this topic with the given endpoint properties
 */
- (id<SLCancelableOperation>) createSubscriptionWithType: (NSString *) subscriptionType
									  endpointProperties: (NSDictionary *) endpointProperties
												   queue: (NSOperationQueue *) completionQueue
									   completionHandler: (void (^)(SLMessagingTopic *client, SLMessagingSubscription *createdSubscription, NSError *error)) completionHandler;

/*!
 Cancel the subscription with the given ID from this topic.
 */
- (id<SLCancelableOperation>) deleteSubscriptionWithID: (NSString *) subscriptionID
												 queue: (NSOperationQueue *) completionQueue
									 completionHandler: (void (^)(BOOL succeeded, NSError *error)) completionHandler;

@end

NSString * const kMessagingTopic_NameKey;
NSString * const kMessagingTopic_TagsProperty;
