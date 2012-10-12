//
//  SLMessagingTopic.m
//  SLMessaging_iOS
//
//  Created by SLDN on 9/14/12.
//  Copyright (c) 2012 SoftLayer Technologies, Inc. All rights reserved.
//

#import <SoftLayerMessaging/SLMessagingMessage.h>
#import <SoftLayerMessaging/SLMessagingSubscription.h>
#import <SoftLayerMessaging/NSArray+BlockOperations.h>


#import "SLMessagingTopic.h"
#import "SLJSONRestResource.h"
#import "NSURL+SLQueryString.h"

NSString * const kMessagingTopic_NameKey = @"name";
NSString * const kMessagingTopic_TagsProperty = @"tags";

@interface SLMessagingTopic ()
@property (strong, readwrite, nonatomic) NSDictionary *jsonRepresentation;
@property (strong, readwrite, nonatomic) SLJSONRestResource *restResource;
@end


@implementation SLMessagingTopic

+ (NSSet *) keyPathsForValuesAffectingValueForKey: (NSString *) key
{
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey: key];

	NSArray *keysInJSONProperties = @[@"name", @"tags"];

	if([keysInJSONProperties containsObject: key])
	{
		keyPaths = [keyPaths setByAddingObject: @"jsonRepresentation"];
	}

	return keyPaths;
}

- (id) initWithRestResource: (SLJSONRestResource *) restResource
				 properties: (NSDictionary *) properties
{
	self = [super init];
	if(self)
	{
		self.restResource = restResource;
		self.jsonRepresentation = properties;
	}

	return self;
}

- (NSString *) description
{
	return [NSString stringWithFormat: @"<%@: %p - %@>", NSStringFromClass([self class]), self, self.name];
}

- (NSString *) name
{
	return (NSString *) _jsonRepresentation[kMessagingTopic_NameKey];
}

- (NSArray *) tags
{
	return (NSArray *) _jsonRepresentation[kMessagingTopic_TagsProperty];
}

- (id<SLCancelableOperation>) retrievePropertiesWithQueue: (NSOperationQueue *) completionQueue
										completionHandler: (void (^)(SLMessagingTopic *topic, NSError *error)) completionHandler
{
	return [self.restResource getWithQueue: completionQueue
						 completionHandler:^(id JSONResult, NSDictionary *responseHeaders, NSError *error) {
							 if(!error)
								 self.jsonRepresentation = JSONResult;
							 completionHandler(self, error);
						 }];
}

- (id<SLCancelableOperation>) updateProperties: (NSDictionary *) properties
										 queue: (NSOperationQueue *) completionQueue
							 completionHandler: (void (^)(SLMessagingTopic *queue, NSError *error)) completionHandler
{
	NSError *jsonConversionError = nil;

	NSData *jsonBody = [NSJSONSerialization dataWithJSONObject: properties options: 0 error: &jsonConversionError];
	if(!jsonBody) {
		[completionQueue addOperationWithBlock:^{
			completionHandler(self, jsonConversionError);
		}];

		return nil;
	}

	return [self.restResource putData: jsonBody
								queue: completionQueue
					completionHandler:^(id JSONResult, NSDictionary *responseHeaders, NSError *error) {
						if(!error)
							self.jsonRepresentation = JSONResult;

						completionHandler(self, error);
					}];
}

- (id<SLCancelableOperation>) deleteTopic: (BOOL) forceDelete
									queue: (NSOperationQueue *) completionQueue
						completionHandler: (void (^)(BOOL succeeded, NSError *error)) completionHandler
{

	SLJSONRestResource *deleteRestResource = self.restResource;
	if(forceDelete)
	{
		NSURL *deleteURL = [self.restResource.resourceURL URLByAppendingQuery: @"force=true"];
		deleteRestResource = [[SLJSONRestResource alloc] initWithResourceURL: deleteURL];
	}

	return [deleteRestResource deleteWithQueue: completionQueue completionHandler:^(id JSONResult, NSDictionary *responseHeaders, NSError *error) {
		completionHandler(nil == error, error);
	}];
}

- (id<SLCancelableOperation>) publishMessage: (NSString *) message
									withTags: (NSArray *) tags
									   queue: (NSOperationQueue *) completionQueue
						   completionHandler: (void (^)(SLMessagingTopic *topic, SLMessagingMessage *publishedMessage, NSError *error)) completionHandler
{
	if(nil == message)
	{
		message = [NSString string];
	}

	NSMutableDictionary *requestBodyJSON = [@{ @"body" : message } mutableCopy];
	if(tags)
	{
		requestBodyJSON[@"tags"] = tags;
	}

	NSError *jsonError = nil;
	NSData *requestBody = [NSJSONSerialization dataWithJSONObject: requestBodyJSON
														  options: 0
															error: &jsonError];

	SLJSONRestResource *messagesResource = [self.restResource resourceAtRelativePath: @"messages"];
	messagesResource.headers = self.restResource.headers;

	id<SLCancelableOperation> request = [messagesResource postData: requestBody
															 queue: completionQueue
												 completionHandler: ^(id JSONResult, NSDictionary *responseHeaders, NSError *error) {
													 if(nil != completionHandler && nil != completionQueue)
													 {
														 if(nil == error && [JSONResult isKindOfClass: [NSDictionary class]])
														 {
															 SLJSONRestResource *messageResource = [self.restResource resourceAtRelativePath: [NSString stringWithFormat: @"messages/%@", JSONResult[@"id"]]];
															 messageResource.headers = self.restResource.headers;

															 SLMessagingMessage *messagePosted = [[SLMessagingMessage alloc] initWithRestResource: messageResource
																																	   properties: JSONResult];

															 completionHandler(self, messagePosted, nil);
														 } else {
															 completionHandler(self, nil, error);
														 }
													 }
												 }];

	return request;
}

- (id<SLCancelableOperation>) requestSubscriptionsWithQueue: (NSOperationQueue *) completionQueue
										  completionHandler: (void (^)(SLMessagingTopic *topic, NSArray *subscriptions, NSError *error)) completionHandler
{
	SLJSONRestResource *subscriptionsResource = [self.restResource resourceAtRelativePath: @"subscriptions"];
	subscriptionsResource.headers = self.restResource.headers;

	return [subscriptionsResource getWithQueue: completionQueue
							 completionHandler: ^(id JSONResult, NSDictionary *responseHeaders, NSError *error) {
								 if(completionHandler)
								 {
									 if(nil == error)
									 {
										 NSAssert([JSONResult isKindOfClass: [NSDictionary class]], @"Expect API to return an a simple object with a list of the queues");
										 NSAssert([[JSONResult allKeys] containsObject: @"items"], @"Expect the object returned to have an 'items' field with the actual queues themselves");

										 /* Pull out the "items" array (make sure it is an array) then create SLMessagingSubscription objects from that array */
										 NSArray *jsonQueuesArray = JSONResult[@"items"];
										 NSAssert([jsonQueuesArray isKindOfClass: [NSArray class]], nil);

										 NSArray *subscriptions = [jsonQueuesArray arrayByCollectingElements: ^id(id JSONQueueObject, NSUInteger idx) {
											 NSString *subscriptionID = JSONQueueObject[@"id"];

											 SLJSONRestResource *subscriptionRestResource = [self.restResource resourceAtRelativePath: [NSString stringWithFormat: @"subscriptions/%@", subscriptionID]];
											 subscriptionRestResource.headers = self.restResource.headers;

											 NSAssert([JSONQueueObject isKindOfClass: [NSDictionary class]], @"Expect that the list of subscriptions contains dictionaries representing each subscription");
											 SLMessagingSubscription *messagingSubscription = [[SLMessagingSubscription alloc] initWithRestResource: subscriptionRestResource properties: JSONQueueObject];

											 return messagingSubscription;
										 }];

										 completionHandler(self, subscriptions, error);
									 } else {
										 completionHandler(self, nil, error);
									 }
								 }
							 }];
}


- (id<SLCancelableOperation>) createSubscriptionWithType: (NSString *) subscriptionType
									  endpointProperties: (NSDictionary *) endpointProperties
												   queue: (NSOperationQueue *) completionQueue
									   completionHandler: (void (^)(SLMessagingTopic *client, SLMessagingSubscription *createdSubscription, NSError *error)) completionHandler
{
	id<SLCancelableOperation> retVal = nil;

	if(!endpointProperties) endpointProperties = @{};
	NSDictionary *subscriptionDetails = @{ @"endpoint_type" : subscriptionType, @"endpoint" : endpointProperties };

	NSError *jsonParseError = nil;
	NSData *httpBody = [NSJSONSerialization dataWithJSONObject: subscriptionDetails options: 0 error: &jsonParseError];
	if(httpBody)
	{
		SLJSONRestResource *subscriptionsResource = [self.restResource resourceAtRelativePath: @"subscriptions"];
		subscriptionsResource.headers = self.restResource.headers;

		retVal = [subscriptionsResource postData: httpBody
										   queue: completionQueue
							   completionHandler: ^(id JSONResult, NSDictionary *responseHeaders, NSError *error) {
								   if(completionHandler)
								   {
									   if(nil == error)
									   {
										   SLJSONRestResource *subscriptionResource = [self.restResource resourceAtRelativePath: [NSString stringWithFormat: @"subscriptions/%@", JSONResult[@"id"]]];
										   SLMessagingSubscription  *newSubscription = [[SLMessagingSubscription alloc] initWithRestResource: subscriptionResource
																																  properties: JSONResult];

										   completionHandler(self, newSubscription, nil);
									   } else {
										   completionHandler(self, nil, error);
									   }
								   }
							   }];
	} else {
		if(completionHandler && completionQueue)
		{
			[completionQueue addOperationWithBlock: ^{
				completionHandler(self, nil, jsonParseError);
			}];
		}
	}

	return retVal;
}

- (id<SLCancelableOperation>) deleteSubscriptionWithID: (NSString *) subscriptionID
												 queue: (NSOperationQueue *) completionQueue
									 completionHandler: (void (^)(BOOL succeeded, NSError *error)) completionHandler;

{
	SLJSONRestResource *subscriptionResource = [self.restResource resourceAtRelativePath: [NSString stringWithFormat: @"subscriptions/%@", subscriptionID]];
	return [subscriptionResource deleteWithQueue: completionQueue
							   completionHandler:^(id JSONResult, NSDictionary *responseHeaders, NSError *error) {
								   completionHandler(nil == error, error);
							   }];
}

@end
