//
//  SLMessagingSubscription.h
//  SLMessaging_iOS
//
//  Created by SLDN on 9/26/12.
//  Copyright (c) 2012 SoftLayer Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SoftLayerMessaging/SLCancelableOperation.h>

@class SLJSONRestResource;

@interface SLMessagingSubscription : NSObject

- (id) initWithRestResource: (SLJSONRestResource *) restResource
				 properties: (NSDictionary *) properties;

@property (readonly, nonatomic) NSString *subscriptionID;
@property (readonly, nonatomic) NSString *endpointType;
@property (readonly, nonatomic) NSString *endpointProperties;

/* Delete this subscription from it's current messaging queue */
- (id<SLCancelableOperation>) deleteSubscriptionWithQueue: (NSOperationQueue *) completionQueue
										completionHandler: (void (^)(BOOL succeeded, NSError *error)) completionHandler;
@end

extern NSString * const kSLMessaging_HTTPEndpointType;
extern NSString * const kSLMessaging_MessagingQueueEndpointType;

/* For subscriptions with and enpoint type of kSLMessaging_MessagingQueueEndpointType */
extern NSString * const kSLMessaging_QueueEndpointNameProperty;

/* For subscriptions with and enpoint type of kSLMessaging_HTTPEndpointType */
extern NSString * const kSLMessaging_HTTPEndpointBodyProperty;
extern NSString * const kSLMessaging_HTTPEndpointHeadersProperty;
extern NSString * const kSLMessaging_HTTPEndpointMethodProperty;
extern NSString * const kSLMessaging_HTTPEndpointParametersProperty;
extern NSString * const kSLMessaging_HTTPEndpointURLProperty;