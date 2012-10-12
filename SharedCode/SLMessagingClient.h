//
//  SLMessagingClient.h
//
//  Created by SLDN on 9/7/12.
//

#import <Foundation/Foundation.h>
#import <SoftLayerMessaging/SLCancelableOperation.h>

#ifndef SLMessagingClient_H_
#define SLMessagingClient_H_

@class SLMessagingQueue;
@class SLMessagingTopic;

@interface SLMessagingClient : NSObject

/*! Return a list of the known messaging hosts supported by the libary */
+ (NSDictionary *) messagingHosts;


/*! Given a data center and network identifier, return the corresponding host
 name of the messaging enpoint */
+ (NSString *) messagingHostForDataCenter: (NSString *) dataCenterID
								  network: (NSString *) networkID;

/*! The SoftLayer messaging account this client was initiated with */
@property (copy, readonly, nonatomic) NSString *messagingAccountID;

/*! Return true if the client is authenticated (and has an authorization token)
 */
@property (readonly, nonatomic, getter=isAuthenticated) BOOL authenticated;

/*!
 Create a new client with the given accountOptions allow you to specify
 either a data center (SLMessagingClientOption_DataCenterKey) and public/private
 network connection (SLMessagingClientOption_NetworkKey), or a complete
 endpoint URL (SLMessagingClientOption_ResourceBaseURL)

 At the moment, the only data center allowed is:
 SLDataCenterID_Dallas5

 on either the SLNetworkID_Public or SLNetworkID_Private networks.

 */
- (id) initWithMessagingAccount: (NSString *) accountID
						options: (NSDictionary *) options;


/*!
 Send a request to authenticate the client with the given username and
 SoftLayer API key. The completion handler will be called on the given
 completionQueue when the request returns
 */
- (id<SLCancelableOperation>) authenticateWithUsername: (NSString *) softLayerUserName
												apiKey: (NSString *) softlayerAPIKey
												 queue: (NSOperationQueue *) completionQueue
									 completionHandler: (void (^)(SLMessagingClient *client, BOOL success, NSError *error)) completionHandler;

#pragma mark - Queue Operations

/*!
 Send a request to create a new messaging queue with the given name and
 properties. (see SLMessagingQueue.h for queue property identifiers)
 */
- (id<SLCancelableOperation>) createMessagingQueueNamed: (NSString *) queueName
											 properties: (NSDictionary *) properties
												  queue: (NSOperationQueue *) completionQueue
									  completionHandler: (void (^)(SLMessagingClient *client, SLMessagingQueue *createdQueue, NSError *error)) completionHandler;

/*!
 Send a request to delete the messaging queue with the given name
 */
- (id<SLCancelableOperation>) deleteMessagingQueueNamed: (NSString *) name
												  force: (BOOL) shouldForceDelete
												  queue: (NSOperationQueue *) completionQueue
									  completionHandler: (void (^)(SLMessagingClient *client, NSError *error)) completionHandler;

/*!
 Send a request to retrieve the details of the message queue with the given name.
 */
- (id<SLCancelableOperation>) getMessagingQueueNamed: (NSString *) queueName
											   queue: (NSOperationQueue *) completionQueue
								   completionHandler: (void (^)(SLMessagingClient *client, SLMessagingQueue *queueFound, NSError *error)) completionHandler;

/*!
 Request a list of message queuesBy default (tagsToListOrNil == nil) the
 entire list of queues in the account are returnedThis list may be limited
 to only those queues that contain a certain set of tags by passing those tags
 in the first parameter.
 */
- (id<SLCancelableOperation>) requestMessagingQueuesWithTags: (NSArray *) tagsToListOrNil
													   queue: (NSOperationQueue *) completionQueue
										   completionHandler: (void (^)(SLMessagingClient *client, NSArray *messagingQueues, NSError *error)) completionHandler;

#pragma mark - Topic Operations

/*!
 Create a new topic with the given properties.  See SLMessagingTopic.h for
 supported properties
 */
- (id<SLCancelableOperation>) createTopicNamed: (NSString *) topicName
									properties: (NSDictionary *) properties
										 queue: (NSOperationQueue *) completionQueue
							 completionHandler: (void (^)(SLMessagingClient *client, SLMessagingTopic *createdTopic, NSError *error)) completionHandler;

/*!
 Delete the topic with the given name permamently from the account.
 */
- (id<SLCancelableOperation>) deleteTopicNamed: (NSString *) name
										 force: (BOOL) shouldForceDelete
										 queue: (NSOperationQueue *) completionQueue
							 completionHandler: (void (^)(SLMessagingClient *client, NSError *error)) completionHandler;

/*!
 Retrieve the Topic with the name given from the server.
 */
- (id<SLCancelableOperation>) getTopicNamed: (NSString *) topicName
									  queue: (NSOperationQueue *) completionQueue
						  completionHandler: (void (^)(SLMessagingClient *client, SLMessagingTopic *topicFound, NSError *error)) completionHandler;

/*!
 Request a list of topics from the server.  If tagsToListOrNil is nil, then the
 request will retrieve a list of all topics.
 */

- (id<SLCancelableOperation>) requestTopicsWithTags: (NSArray *) tagsToListOrNil
											  queue: (NSOperationQueue *) completionQueue
								  completionHandler: (void (^)(SLMessagingClient *client, NSArray *queues, NSError *error)) completionHandler;

#pragma mark - Other Operations

/*!
 Ping the messaging endpoint to see if it is reachable on the current network
 */
- (id<SLCancelableOperation>) pingWithQueue: (NSOperationQueue *) completionQueue
						  completionHandler: (void (^)(SLMessagingClient *client, BOOL succeeded, NSError *error)) completionHandler;

/*!
 Request a set of usage statistiscs about the service.
 */
- (id<SLCancelableOperation>) requestStatistics: (NSString *) statistics
									  withQueue: (NSOperationQueue *) completionQueue
							  completionHandler: (void (^)(SLMessagingClient *client, NSDictionary *usageStatistics, NSError *error)) completionHandler;

@end

#pragma mark - Options For Initialization

/* Dictionary keys to use when passing options to the initializer */
extern NSString * const SLMessagingClientOption_ResourceBaseURL;	/* By default, the endpoint URL is calculated from the data center and network
																	 this option lets you override those two values to provide your own base URL */
extern NSString * const SLMessagingClientOption_DataCenterKey;		/* defaults to SLDataCenterID_Dallas5 */
extern NSString * const SLMessagingClientOption_NetworkKey;			/* defaults to SLNetworkID_Public */

/* Data Center identifiers */
extern NSString * const SLDataCenterID_Dallas5;

/* Network selectors */
extern NSString * const SLNetworkID_Public;
extern NSString * const SLNetworkID_Private;


# pragma mark - Available Statistics

/* Statistics types for the requestStatistics call */
extern NSString * const kSLMessagingClient_StatisticsForPastHour;
extern NSString * const kSLMessagingClient_StatisticsForPastDay;
extern NSString * const kSLMessagingClient_StatisticsForPastWeek;
extern NSString * const kSLMessagingClient_StatisticsForPastMonth;
#endif // SLMessagingClient_H_