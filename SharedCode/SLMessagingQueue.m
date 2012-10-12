//
//  SLMessagingQueue.m
//  SLMessaging
//
//  Created by SLDN on 9/12/12.
//  Copyright (c) 2012 SoftLayer Technologies, Inc. All rights reserved.
//

#import "SLMessagingQueue.h"
#import "SLJSONRestResource.h"
#import "SLMessagingMessage.h"

#import "NSURL+SLQueryString.h"
#import "NSArray+BlockOperations.h"

NSString * const kMessagingQueue_NameKey = @"name";
NSString * const kMessagingQueue_MessageCountKey = @"message_count";
NSString * const kMessagingQueue_VisibleMessageCountKey = @"visible_message_count";

NSString * const kMessagingQueue_TagsProperty = @"tags";
NSString * const kMessagingQueue_VisibiltyIntervalProperty = @"visibility_interval";
NSString * const kMessagingQueue_ExpirationIntervalProperty = @"expiration";

@interface SLMessagingQueue ()
@property (strong, readwrite, nonatomic) SLJSONRestResource *restResource;
@property (strong, readwrite, nonatomic) NSDictionary *jsonRepresentation;
@end

@implementation SLMessagingQueue

+ (NSSet *) keyPathsForValuesAffectingValueForKey: (NSString *) key
{
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey: key];

	NSArray *keysInJSONProperties = @[@"name", @"tags", @"messageCount", @"visibleMessageCount", @"visibilityInterval", @"expirationInterval"];

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
	return (NSString *) _jsonRepresentation[kMessagingQueue_NameKey];
}

- (NSArray *) tags
{
	id tagsFromJson = _jsonRepresentation[kMessagingQueue_TagsProperty];

	if(!tagsFromJson || [NSNull null] == tagsFromJson)
	{
		tagsFromJson = @[];
	}

	return (NSArray *) tagsFromJson;
}

- (NSUInteger) messageCount
{
	return [_jsonRepresentation[kMessagingQueue_MessageCountKey] unsignedIntegerValue];
}

- (NSUInteger) visibleMessageCount
{
	return [_jsonRepresentation[kMessagingQueue_VisibleMessageCountKey] unsignedIntegerValue];
}

- (NSTimeInterval) visibilityInterval
{
	return [_jsonRepresentation[kMessagingQueue_VisibiltyIntervalProperty] doubleValue];
}

- (NSTimeInterval) expirationInterval
{
	return [_jsonRepresentation[kMessagingQueue_ExpirationIntervalProperty] doubleValue];
}

- (id<SLCancelableOperation>) retrievePropertiesWithQueue: (NSOperationQueue *) completionQueue
										completionHandler: (void (^)(SLMessagingQueue *queue, NSError *error)) completionHandler
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
							 completionHandler: (void (^)(SLMessagingQueue *queue, NSError *error)) completionHandler
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

- (id<SLCancelableOperation>) deleteMessagingQueue: (BOOL) forceDelete
											 queue: (NSOperationQueue *) completionQueue
								 completionHandler: (void (^)(BOOL succeeded, NSError *error)) completionHandler
{

	SLJSONRestResource *deleteRestResource = self.restResource;
	if(forceDelete)
	{
		NSURL *deleteURL = [self.restResource.resourceURL URLByAppendingQuery: @"force=true"];
		deleteRestResource = [[SLJSONRestResource alloc] initWithResourceURL: deleteURL];
	}

	return [deleteRestResource deleteWithQueue: completionQueue completionHandler: ^(id JSONResult, NSDictionary *responseHeaders, NSError *error) {
		completionHandler(nil == error, error);
	}];
}

- (id<SLCancelableOperation>) publishMessage: (NSString *) message
								  withFields: (NSDictionary *) additionalFieldsOrNil
									   queue: (NSOperationQueue *) completionQueue
						   completionHandler: (void (^)(SLMessagingQueue *queue, SLMessagingMessage *postedMessage, NSError *error)) completionHandler
{
	if(nil == message)
	{
		message = [NSString string];
	}

	NSMutableDictionary *requestBodyJSON = [@{ @"body" : message } mutableCopy];
	if(additionalFieldsOrNil)
	{
		requestBodyJSON[@"fields"] = additionalFieldsOrNil;
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

- (id<SLCancelableOperation>) requestMessagesWithLimit: (NSUInteger) numberToRetrieve
												 queue: (NSOperationQueue *) completionQueue
									 completionHandler: (void (^)(SLMessagingQueue *queue, NSArray *visibleMessages, NSError *error)) completionHandler
{
	if(numberToRetrieve == 0)
	{
		numberToRetrieve = 1;
	}

	NSURL *messagesURL = [self.restResource.resourceURL URLByAppendingPathComponent: @"messages"];
	messagesURL = [messagesURL URLByAppendingQuery: [NSString stringWithFormat: @"batch=%d", (unsigned int)numberToRetrieve]];

	SLJSONRestResource *popMessagesResource = [[SLJSONRestResource alloc] initWithResourceURL: messagesURL];
	popMessagesResource.headers = self.restResource.headers;

	id<SLCancelableOperation> request = [popMessagesResource getWithQueue: completionQueue
														completionHandler: ^(id JSONResult, NSDictionary *responseHeaders, NSError *error) {
															if(nil != completionHandler && nil != completionQueue)
															{
																if(nil == error && [JSONResult isKindOfClass: [NSDictionary class]]) {
																	NSArray *jsonMessages = JSONResult[@"items"];
																	NSArray *messages = [jsonMessages arrayByCollectingElements:^id(NSDictionary *jsonMessage, NSUInteger idx) {
																		SLJSONRestResource *messageResource = [self.restResource resourceAtRelativePath: [NSString stringWithFormat: @"messages/%@", jsonMessage[@"id"]]];
																		messageResource.headers = self.restResource.headers;

																		SLMessagingMessage *messageFound = [[SLMessagingMessage alloc] initWithRestResource: messageResource
																																				 properties: jsonMessage];
																		return messageFound;
																	}];

																	completionHandler(self, messages, nil);
																} else {
																	completionHandler(self, nil, error);
																}
															}
														}];

	return request;
}

- (id<SLCancelableOperation>) deleteMessageWithID: (NSString *) messageID
											queue: (NSOperationQueue *) completionQueue
								completionHandler: (void (^)(BOOL succeeded, NSError *error)) completionHandler
{
	SLJSONRestResource *messageResource = [self.restResource resourceAtRelativePath: [NSString stringWithFormat: @"messages/%@", messageID]];
	return [messageResource deleteWithQueue: completionQueue
						  completionHandler:^(id JSONResult, NSDictionary *responseHeaders, NSError *error) {
							  completionHandler(nil == error, error);
						  }];
}

@end

