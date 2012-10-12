//
//  SLMessagingSubscription.m
//  SLMessaging_iOS
//
//  Created by SLDN on 9/26/12.
//  Copyright (c) 2012 SoftLayer Technologies, Inc. All rights reserved.
//

#import "SLMessagingSubscription.h"

#import "SLJSONRestResource.h"

NSString * const kSLMessaging_HTTPEndpointType = @"http";
NSString * const kSLMessaging_MessagingQueueEndpointType = @"queue";

NSString * const kSLMessaging_QueueEndpointNameProperty = @"queue_name";

NSString * const kSLMessaging_HTTPEndpointMethodProperty = @"method";
NSString * const kSLMessaging_HTTPEndpointURLProperty = @"url";
NSString * const kSLMessaging_HTTPEndpointParametersProperty = @"params";
NSString * const kSLMessaging_HTTPEndpointHeadersProperty = @"headers";
NSString * const kSLMessaging_HTTPEndpointBodyProperty = @"body";

@interface SLMessagingSubscription ()
@property (strong, readwrite, nonatomic) SLJSONRestResource *restResource;
@property (strong, readwrite, nonatomic) NSDictionary *jsonRepresentation;
@end


@implementation SLMessagingSubscription

+ (NSSet *) keyPathsForValuesAffectingValueForKey: (NSString *) key
{
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey: key];

	NSArray *keysInJSONProperties = @[@"subscriptionID", @"endpointType", @"endpointProperties"];

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

- (NSString *) subscriptionID
{
	return self.jsonRepresentation[@"id"];
}

- (NSString *) endpointProperties
{
	return self.jsonRepresentation[@"endpoint"];
}

- (NSString *) endpointType
{
	return self.jsonRepresentation[@"endpoint_type"];
}

- (NSString *) description
{
	return [NSString stringWithFormat: @"<%@: %p - %@>", NSStringFromClass([self class]), self, self.subscriptionID];
}

- (id<SLCancelableOperation>) deleteSubscriptionWithQueue: (NSOperationQueue *) completionQueue
										completionHandler: (void (^)(BOOL succeeded, NSError *error)) completionHandler;
{
	return [self.restResource deleteWithQueue: completionQueue completionHandler:^(id JSONResult, NSDictionary *responseHeaders, NSError *error) {
		completionHandler(nil == error, error);
	}];
}
@end
