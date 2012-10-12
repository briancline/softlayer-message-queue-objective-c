//
//  SLMessagingMessage.m
//  SLMessaging_iOS
//
//  Created by SLDN on 9/26/12.
//  Copyright (c) 2012 SoftLayer Technologies, Inc. All rights reserved.
//

#import "SLMessagingMessage.h"

#import "SLJSONRestResource.h"


@interface SLMessagingMessage ()
@property (strong, readwrite, nonatomic) SLJSONRestResource *restResource;
@property (strong, readwrite, nonatomic) NSDictionary *jsonRepresentation;
@end


@implementation SLMessagingMessage

+ (NSSet *) keyPathsForValuesAffectingValueForKey: (NSString *) key
{
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey: key];

	NSArray *keysInJSONProperties = @[@"body", @"messageID", @"initialEntryTime"];

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

- (NSString *) body
{
	return self.jsonRepresentation[@"body"];
}

- (NSString *) messageID
{
	return self.jsonRepresentation[@"id"];
}

- (NSString *) description
{
	return [NSString stringWithFormat: @"<%@: %p - %@>", NSStringFromClass([self class]), self, self.messageID];
}

- (NSDate *) initialEntryTime
{
	NSTimeInterval entryInterval = [self.jsonRepresentation[@"initial_entry_time"] doubleValue];

	return [NSDate dateWithTimeIntervalSince1970: entryInterval];
}

- (id<SLCancelableOperation>) deleteMessageWithQueue: (NSOperationQueue *) completionQueue
								   completionHandler: (void (^)(BOOL succeeded, NSError *error)) completionHandler
{
	return [self.restResource deleteWithQueue: completionQueue completionHandler:^(id JSONResult, NSDictionary *responseHeaders, NSError *error) {
		completionHandler(nil == error, error);
	}];
}
@end
