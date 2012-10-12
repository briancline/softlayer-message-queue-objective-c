//
//  SLMessagingClient.m
//
//
//  Created by SLDN on 9/7/12.
//
//

#import <SoftLayerMessaging/SLJSONRestResource.h>
#import "SLMessagingClient.h"

#import "SLHTTPRequest.h"
#import "SLMessagingQueue.h"
#import "SLMessagingTopic.h"
#import "NSArray+BlockOperations.h"
#import "NSURL+SLQueryString.h"

NSString * const SLDataCenterID_Dallas5 = @"dal05";
NSString * const SLNetworkID_Public = @"public";
NSString * const SLNetworkID_Private = @"private";

NSString * const SLMessagingClientOption_DataCenterKey = @"SLMessagingClientOption_DataCenterKey";
NSString * const SLMessagingClientOption_NetworkKey = @"SLMessagingClientOption_NetworkKey";
NSString * const SLMessagingClientOption_ResourceBaseURL = @"SLMessagingClientOption_ResourceBaseURL";

NSString * const kSLMessagingClient_StatisticsForPastHour = @"hour";
NSString * const kSLMessagingClient_StatisticsForPastDay = @"day";
NSString * const kSLMessagingClient_StatisticsForPastWeek = @"week";
NSString * const kSLMessagingClient_StatisticsForPastMonth = @"month";

static NSString * const SLAuthenticationHeader_Username = @"X-Auth-User";
static NSString * const SLAuthenticationHeader_APIKey = @"X-Auth-Key";
static NSString * const SLAuthenticationHeader_AuthToken = @"X-Auth-Token";

extern NSString * const kMessagingQueue_NameKey;

@interface SLMessagingClient ()
@property (copy, readwrite, nonatomic) NSString *messagingAccountID;
@property (copy, readwrite, nonatomic) NSString *authenticationToken;
@property (strong, readwrite, nonatomic) SLJSONRestResource *accountRestResource;
@end

@implementation SLMessagingClient

@synthesize messagingAccountID;

+ (NSDictionary *) messagingHosts
{
	return @{
	SLDataCenterID_Dallas5 : @{
	SLNetworkID_Public : @"dal05.mq.softlayer.net",
	SLNetworkID_Private : @"dal05.mq.service.networklayer.com"
	}
	};
}

+ (NSString *) messagingHostForDataCenter: (NSString *) dataCenterID
								  network: (NSString *) networkID
{
	return [self messagingHosts][dataCenterID][networkID];
}


- (BOOL) isAuthenticated
{
	return self.authenticationToken && [self.authenticationToken length] > 0;
}

- (id<SLCancelableOperation>) authenticateWithUsername: (NSString *) softLayerUserName
												apiKey: (NSString *) softlayerAPIKey
												 queue: (NSOperationQueue *) completionQueue
									 completionHandler: (void (^)(SLMessagingClient *client, BOOL success, NSError *error)) completionHandler
{
	SLJSONRestResource *authResource = [self.accountRestResource resourceAtRelativePath: @"auth"];
	authResource.headers = @{ SLAuthenticationHeader_Username : softLayerUserName, SLAuthenticationHeader_APIKey: softlayerAPIKey };

	return [authResource postData: [NSData data]
							queue: completionQueue
				completionHandler: ^(id JSONResult, NSDictionary *responseHeaders, NSError *error) {
					if(nil != completionHandler)
					{
						if(!error)
						{
							self.authenticationToken = JSONResult[@"token"];
						}

						completionHandler(self, nil == error, error);
					}
				}];
}

- (id<SLCancelableOperation>) requestMessagingQueuesWithTags: (NSArray *) tagsToListOrNil
													   queue: (NSOperationQueue *) completionQueue
										   completionHandler: (void (^)(SLMessagingClient *client, NSArray *messagingQueues, NSError *error)) completionHandler
{
	/* Pull together a complete URL with the tags query as needed */
	NSURL *queuesURL = [self.accountRestResource.resourceURL URLByAppendingPathComponent: @"queues"];
	if(nil != tagsToListOrNil && [tagsToListOrNil count] > 0)
	{
		NSString *tags = [tagsToListOrNil componentsJoinedByString: @","];
		tags = [tags stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
		queuesURL = [queuesURL URLByAppendingQuery: [NSString stringWithFormat: @"tags=%@", tags]];
	}

	SLJSONRestResource *queuesWithTagsResource = [[SLJSONRestResource alloc] initWithResourceURL: queuesURL];
	queuesWithTagsResource.headers = @{ SLAuthenticationHeader_AuthToken : self.authenticationToken };

	return [queuesWithTagsResource getWithQueue: completionQueue
							  completionHandler: ^(id JSONResult, NSDictionary *responseHeaders, NSError *error) {
								  if(completionHandler)
								  {
									  if(nil == error)
									  {
										  NSAssert([JSONResult isKindOfClass: [NSDictionary class]], @"Expect API to return an a simple object with a list of the queues");
										  NSAssert([[JSONResult allKeys] containsObject: @"items"], @"Expect the object returned to have an 'items' field with the actual queues themselves");

										  /* Pull out the "items" array (make sure it is an array) then create SLMessagingQueue objects from that array */
										  NSArray *jsonQueuesArray = JSONResult[@"items"];
										  NSAssert([jsonQueuesArray isKindOfClass: [NSArray class]], nil);

										  NSArray *queueObjects = [jsonQueuesArray arrayByCollectingElements: ^id(id JSONQueueObject, NSUInteger idx) {
											  NSString *queueName = JSONQueueObject[@"name"];

											  SLJSONRestResource *queueRestResource = [self.accountRestResource resourceAtRelativePath: [NSString stringWithFormat: @"queues/%@", queueName]];
											  queueRestResource.headers = @{ SLAuthenticationHeader_AuthToken : self.authenticationToken };

											  NSAssert([JSONQueueObject isKindOfClass: [NSDictionary class]], @"Expect that the list of queue objects contains dictionaries representing each queue");
											  SLMessagingQueue *messagingQueue = [[SLMessagingQueue alloc] initWithRestResource: queueRestResource properties: JSONQueueObject];

											  return messagingQueue;
										  }];

										  completionHandler(self, queueObjects, error);
									  } else {
										  completionHandler(self, nil, error);
									  }
								  }
							  }];
}

- (id<SLCancelableOperation>) createMessagingQueueNamed: (NSString *) queueName
											 properties: (NSDictionary *) properties
												  queue: (NSOperationQueue *) completionQueue
									  completionHandler: (void (^)(SLMessagingClient *client, SLMessagingQueue *createdQueue, NSError *error)) completionHandler
{
	if(!properties) properties = @{};

	id<SLCancelableOperation> retVal = nil;
	NSString *httpSafeName = [queueName stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];

	SLJSONRestResource *queueRestResource = [self.accountRestResource resourceAtRelativePath: [NSString stringWithFormat: @"queues/%@", httpSafeName]];
	queueRestResource.headers = @{ SLAuthenticationHeader_AuthToken : self.authenticationToken };

	NSMutableDictionary *finalProperties = [properties mutableCopy];
	finalProperties[kMessagingQueue_NameKey] = queueName;

	SLMessagingQueue *newQueue = [[SLMessagingQueue alloc] initWithRestResource: queueRestResource
																	 properties: finalProperties];

	NSError *jsonParseError = nil;
	NSData *httpBody = [NSJSONSerialization dataWithJSONObject: properties options: 0 error: &jsonParseError];
	if(httpBody)
	{
		retVal = [queueRestResource putData: httpBody
									  queue: completionQueue
						  completionHandler: ^(id JSONResult, NSDictionary *responseHeaders, NSError *error) {
							  if(completionHandler)
							  {
								  if(nil == error)
								  {
									  completionHandler(self, newQueue, nil);

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

- (id<SLCancelableOperation>) deleteMessagingQueueNamed: (NSString *) name
												  force: (BOOL) shouldForceDelete
												  queue: (NSOperationQueue *) completionQueue
									  completionHandler: (void (^)(SLMessagingClient *client, NSError *error)) completionHandler
{
	NSURL *namedQueueURL = [self.accountRestResource.resourceURL URLByAppendingPathComponent: @"queues"];
	namedQueueURL = [namedQueueURL URLByAppendingPathComponent: name];

	if(shouldForceDelete)
	{
		namedQueueURL = [namedQueueURL URLByAppendingQuery: @"force=true"];
	}

	SLJSONRestResource *deleteQueueResource = [[SLJSONRestResource alloc] initWithResourceURL: namedQueueURL];
	deleteQueueResource.headers = @{ SLAuthenticationHeader_AuthToken : self.authenticationToken };

	return [deleteQueueResource deleteWithQueue: completionQueue
							  completionHandler: ^(id JSONResult, NSDictionary *responseHeaders, NSError *error) {
								  if(completionHandler)
								  {
									  completionHandler(self, error);
								  }
							  }];
}

- (id<SLCancelableOperation>) getMessagingQueueNamed: (NSString *) queueName
											   queue: (NSOperationQueue *) completionQueue
								   completionHandler: (void (^)(SLMessagingClient *client, SLMessagingQueue *queueFound, NSError *error)) completionHandler
{
	SLJSONRestResource *queueRestResource = [self.accountRestResource resourceAtRelativePath: [NSString stringWithFormat: @"queues/%@", queueName]];
	queueRestResource.headers = @{ SLAuthenticationHeader_AuthToken : self.authenticationToken };

	return [queueRestResource getWithQueue: completionQueue
						 completionHandler: ^(id JSONResult, NSDictionary *responseHeaders, NSError *error) {
							 if(completionHandler)
							 {
								 if(nil == error) {
									 NSAssert([JSONResult isKindOfClass: [NSDictionary class]], @"Expect API to return an object");

									 SLMessagingQueue *messagingQueue = [[SLMessagingQueue alloc] initWithRestResource: queueRestResource
																											properties: JSONResult];
									 completionHandler(self, messagingQueue, error);
								 } else {
									 completionHandler(self, nil, error);
								 }
							 }
						 }];
}

- (id<SLCancelableOperation>) requestTopicsWithTags: (NSArray *) tagsToListOrNil
											  queue: (NSOperationQueue *) completionQueue
								  completionHandler: (void (^)(SLMessagingClient *client, NSArray *queues, NSError *error)) completionHandler
{
	NSURL *topicsURL = [self.accountRestResource.resourceURL URLByAppendingPathComponent: @"topics"];
	if(nil != tagsToListOrNil && [tagsToListOrNil count] > 0)
	{
		NSString *tags = [tagsToListOrNil componentsJoinedByString: @","];
		tags = [tags stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
		topicsURL = [topicsURL URLByAppendingQuery: [NSString stringWithFormat: @"tags=%@", tags]];
	}

	SLJSONRestResource *topicsResource = [[SLJSONRestResource alloc] initWithResourceURL: topicsURL];
	topicsResource.headers =  @{ SLAuthenticationHeader_AuthToken : self.authenticationToken };

	return [topicsResource getWithQueue: completionQueue
					  completionHandler: ^(id JSONResult, NSDictionary *responseHeaders, NSError *error) {
						  if(completionHandler)
						  {
							  if(nil == error)
							  {
								  NSAssert([JSONResult isKindOfClass: [NSDictionary class]], @"Expect API to return an a simple object with a list of the queues");
								  NSAssert([[JSONResult allKeys] containsObject: @"items"], @"Expect the object returned to have an 'items' field with the actual queues themselves");

								  /* Pull out the "items" array (make sure it's an array) then create SLMessagingQueue objects from that array */
								  NSArray *jsonQueuesArray = JSONResult[@"items"];
								  NSAssert([jsonQueuesArray isKindOfClass: [NSArray class]], nil);

								  NSArray *queueObjects = [jsonQueuesArray arrayByCollectingElements: ^id(id JSONTopicObject, NSUInteger idx) {
									  NSAssert([JSONTopicObject isKindOfClass: [NSDictionary class]], @"Expect that the list of queue objects contains dictionaries representing each queue");

									  NSString *topicName = JSONTopicObject[@"name"];

									  SLJSONRestResource *topicRestResource = [self.accountRestResource resourceAtRelativePath: [NSString stringWithFormat: @"topic/%@", topicName]];
									  topicRestResource.headers = @{ SLAuthenticationHeader_AuthToken : self.authenticationToken };

									  SLMessagingTopic *newTopic = [[SLMessagingTopic alloc] initWithRestResource: topicRestResource
																									   properties: JSONTopicObject];
									  return newTopic;
								  }];

								  completionHandler(self, queueObjects, error);
							  } else {
								  completionHandler(self, nil, error);
							  }
						  }
					  }];
}

- (id<SLCancelableOperation>) createTopicNamed: (NSString *) topicName
									properties: (NSDictionary *) properties
										 queue: (NSOperationQueue *) completionQueue
							 completionHandler: (void (^)(SLMessagingClient *client, SLMessagingTopic *createdTopic, NSError *error)) completionHandler
{
	if(!properties) properties = @{};

	id<SLCancelableOperation> retVal = nil;
	NSString *httpSafeName = [topicName stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];

	SLJSONRestResource *topicRestResource = [self.accountRestResource resourceAtRelativePath: [NSString stringWithFormat: @"topics/%@", httpSafeName]];
	topicRestResource.headers = @{ SLAuthenticationHeader_AuthToken : self.authenticationToken };

	NSMutableDictionary *finalProperties = [properties mutableCopy];
	finalProperties[kMessagingTopic_NameKey] = topicName;

	SLMessagingTopic *newTopic = [[SLMessagingTopic alloc] initWithRestResource: topicRestResource
																	 properties: finalProperties];


	NSError *jsonParseError = nil;
	NSData *httpBody = [NSJSONSerialization dataWithJSONObject: properties options: 0 error: &jsonParseError];
	if(httpBody)
	{
		retVal = [topicRestResource putData: httpBody
									  queue: completionQueue
						  completionHandler: ^(id JSONResult, NSDictionary *responseHeaders, NSError *error) {
							  if(completionHandler)
							  {
								  if(nil == error)
								  {
									  completionHandler(self, newTopic, nil);
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

- (id<SLCancelableOperation>) deleteTopicNamed: (NSString *) name
										 force: (BOOL) shouldForceDelete
										 queue: (NSOperationQueue *) completionQueue
							 completionHandler: (void (^)(SLMessagingClient *client, NSError *error)) completionHandler
{

	NSURL *namedTopicURL = [self.accountRestResource.resourceURL URLByAppendingPathComponent: @"topics"];
	namedTopicURL = [namedTopicURL URLByAppendingPathComponent: name];

	if(shouldForceDelete)
	{
		namedTopicURL = [namedTopicURL URLByAppendingQuery: @"force=true"];
	}

	SLJSONRestResource *deleteTopicResource = [[SLJSONRestResource alloc] initWithResourceURL: namedTopicURL];
	deleteTopicResource.headers = @{ SLAuthenticationHeader_AuthToken : self.authenticationToken };

	return [deleteTopicResource deleteWithQueue: completionQueue
							  completionHandler: ^(id JSONResult, NSDictionary *responseHeaders, NSError *error) {
								  if(completionHandler)
								  {
									  completionHandler(self, error);
								  }
							  }];
}

- (id<SLCancelableOperation>) getTopicNamed: (NSString *) topicName
									  queue: (NSOperationQueue *) completionQueue
						  completionHandler: (void (^)(SLMessagingClient *client, SLMessagingTopic *topicFound, NSError *error)) completionHandler
{
	SLJSONRestResource *topicRestResource = [self.accountRestResource resourceAtRelativePath: [NSString stringWithFormat: @"topics/%@", topicName]];
	topicRestResource.headers = @{ SLAuthenticationHeader_AuthToken : self.authenticationToken };

	return [topicRestResource getWithQueue: completionQueue
						 completionHandler: ^(id JSONResult, NSDictionary *responseHeaders, NSError *error) {
							 if(completionHandler)
							 {
								 if(nil == error) {
									 NSAssert([JSONResult isKindOfClass: [NSDictionary class]], @"Expect API to return an object");

									 SLMessagingTopic *messagingTopic = [[SLMessagingTopic alloc] initWithRestResource: topicRestResource
																											properties:  JSONResult];
									 completionHandler(self, messagingTopic, error);
								 } else {
									 completionHandler(self, nil, error);
								 }
							 }
						 }];
}

- (id<SLCancelableOperation>) pingWithQueue: (NSOperationQueue *) completionQueue
						  completionHandler: (void (^)(SLMessagingClient *client, BOOL succeeded, NSError *error)) completionHandler
{
	// The ping request does not return JSON so we'll use a direct HTTP request instead of relying
	// on the JSON client "get" method (which would try to parse the result as JSON).

	NSURL *pingURL = [self.accountRestResource.resourceURL URLByAppendingPathComponent: @"ping"];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: pingURL];
	request.HTTPMethod = @"GET";

	SLHTTPRequest *httpRequest = [SLHTTPRequest requestToLoadNSURLRequest: request];
	[httpRequest executeOnQueue: completionQueue
			  completionHandler: ^(NSHTTPURLResponse *response, NSData *data, NSError *networkError) {
				  if(completionHandler)
				  {
					  if(!networkError)
					  {
						  if(HTTPStatusIndicatesSuccess(response.statusCode))
						  {
							  completionHandler(self, YES, nil);
						  } else {
							  NSError *statusError = [SLHTTPRequest errorForFailedHTTPResponse: response additionalUserInfo: nil];
							  completionHandler(self, NO, statusError);
						  }
					  } else {
						  completionHandler(self, NO, networkError);
					  }
				  }
			  }];

	return httpRequest;
}

- (id<SLCancelableOperation>) requestStatistics: (NSString *) statistics
									  withQueue: (NSOperationQueue *) completionQueue
							  completionHandler: (void (^)(SLMessagingClient *client, NSDictionary *usageStatistics, NSError *error)) completionHandler
{
	SLJSONRestResource *statsResource = [self.accountRestResource resourceAtRelativePath: [NSString stringWithFormat: @"stats/%@", statistics]];
	[statsResource getWithQueue: completionQueue completionHandler:^(id JSONResult, NSDictionary *responseHeaders, NSError *error) {
		completionHandler(self, JSONResult, error);
	}];

	return nil;
}


- (id) initWithMessagingAccount: (NSString *) accountID
						options: (NSDictionary *) options
{

	NSURL *resourceBaseURL;

	NSAssert(nil != accountID, nil);
	NSAssert([accountID length] > 0, nil);

	if(nil == accountID || 0 == [accountID length])
	{
		[NSException raise: NSInvalidArgumentException format: @"Account ID Required to create %@", NSStringFromClass([self class])];
	}


	id endpointURLOption = options[SLMessagingClientOption_ResourceBaseURL];
	if(!endpointURLOption)
	{
		NSString *dataCenterID = options[SLMessagingClientOption_DataCenterKey];
		NSString *networkID = options[SLMessagingClientOption_NetworkKey];

		if(!dataCenterID) {
			dataCenterID = SLDataCenterID_Dallas5;
		}

		if(!networkID) {
			networkID = SLNetworkID_Public;
		}

		NSString *endpointHost = [[self class] messagingHostForDataCenter: dataCenterID network: networkID];
		NSString *urlString = [NSString stringWithFormat: @"https://%@/v1/", endpointHost];

		resourceBaseURL = [NSURL URLWithString: urlString];
	} else {
		if([endpointURLOption isKindOfClass: [NSString class]])
		{
			resourceBaseURL = [NSURL URLWithString: endpointURLOption];
		}

		if([endpointURLOption isKindOfClass: [NSURL class]])
		{
			resourceBaseURL = endpointURLOption;
		}

		resourceBaseURL = [[NSURL URLWithString: @"v1/" relativeToURL: resourceBaseURL] absoluteURL];
	}

	self = [super init];
	if(self)
	{
		self.messagingAccountID = accountID;
		self.authenticationToken = @"";
		
		NSURL *accountBaseURL = [NSURL URLWithString: self.messagingAccountID relativeToURL: resourceBaseURL];
		self.accountRestResource = [[SLJSONRestResource alloc] initWithResourceURL: accountBaseURL];
	}
	
	return self;
}
@end
