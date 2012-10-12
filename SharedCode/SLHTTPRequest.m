//
//  SLHTTPRequest.m
//  SLOpenStackAPI
//
//  Created by SLDN on 10/12/11.
//  Copyright (c) 2011 SoftLayer Technologies, Inc. All rights reserved.
//

#import <libkern/OSAtomic.h>
#import "NSError+SLUserCancelled.h"

#import "SLHTTPRequest.h"
#import "SLRAMBasedDataStrategy.h"

#ifdef DEBUG
#define LOG_NETWORK_REQUESTS 0
#define LOG_REQUEST_COMPLETIONS 0
#define LOG_AUTHENTICATION_CHALLENGES 0
#define TRUST_INVALID_SSL_CERTS 0
#else
#define LOG_NETWORK_REQUESTS 0
#define LOG_REQUEST_COMPLETIONS 0
#define LOG_AUTHENTICATION_CHALLENGES 0
#define TRUST_INVALID_SSL_CERTS 0
#endif

NSString * const kHTTPStatusCodeErrorDomain = @"HTTPStatusCodeErrorDomain";

@interface SLHTTPRequest ()
{
	uint32_t hasCompleted;
	NSURLRequest *urlRequest;
	NSURLConnection *urlConnection;
}

@property (strong, nonatomic) NSOperationQueue *completionQueue;
@property (copy, nonatomic) SLHTTPConnectionHandler completionBlock;

@property (strong, nonatomic) NSHTTPURLResponse *lastResponse;

@end

@implementation SLHTTPRequest

@synthesize dataCollector;
@synthesize lastResponse;
@synthesize urlCredentials;

@synthesize completionQueue;
@synthesize completionBlock;

+ (SLHTTPRequest *) requestToLoadNSURLRequest: (NSURLRequest *) urlRequest
{
	NSAssert(nil != urlRequest, nil);

	SLHTTPRequest *newRequest = [[SLHTTPRequest alloc] initWithURLRequest: urlRequest];
	return newRequest;
}

- (id) initWithURLRequest: (NSURLRequest *) _urlRequest
{
	self = [super init];
	if(self)
	{
		urlRequest = _urlRequest;
		self.dataCollector = [[SLRAMBasedDataStrategy alloc] init];
	}

	return self;
}

- (void) executeOnQueue: (NSOperationQueue *) queue
	  completionHandler: (SLHTTPConnectionHandler) _completionBlock;
{
	// Clear the hasCompleted flag getting ready to run the connection
	OSAtomicTestAndClear(0, &hasCompleted);

	urlConnection = [[NSURLConnection alloc] initWithRequest: urlRequest
													delegate: self
											startImmediately: NO];
	if(urlConnection)
	{
		self.completionBlock = _completionBlock;
		self.completionQueue = queue;

		[urlConnection scheduleInRunLoop: [NSRunLoop mainRunLoop] forMode: NSDefaultRunLoopMode];
		[urlConnection start];
	}
}

- (void) executeSynchronous: (SLHTTPConnectionHandler) _completionBlock
{
	NSHTTPURLResponse *requestResponse;
	NSError *requestError;

	// Synchronus calls on the main thread can get us killed by the watchdog
	// timer so warn if someone tries to run one.
	if(dispatch_get_main_queue() == dispatch_get_current_queue())
	{
		NSLog(@"executeSynchronous called to make Synchronous Network call made on main thread");
	}

	// Clear the hasCompleted flag getting ready to run the connection
	OSAtomicTestAndClear(0, &hasCompleted);

	NSData *result = [NSURLConnection sendSynchronousRequest: urlRequest returningResponse: &requestResponse error: &requestError];

	OSAtomicTestAndSet(0, &hasCompleted);

	if(_completionBlock)
	{
		_completionBlock(requestResponse, result, requestError);
	}
}

- (void) cancel
{
	NSError *userCancelledError = [NSError sl_userCancelledError];
	[self abortConnectionWithError: userCancelledError];
}

#pragma mark - Private methods

- (void) abortConnectionWithError: (NSError *) connectionError
{
#if LOG_REQUEST_COMPLETIONS
	NSLog(@"Request aborted on queue %@", [[NSOperationQueue currentQueue] name]);
#endif

	// abortConnectionWithError, connectionDidFinishLoading, and
	// connectionDidFailWithError could be called on different threadsIf one
	// of these methods gets called, we want to make sure the others don't try
	// to call the completion handler too. We use an atomic "test and set" to
	// ensure that only one of these methods will actually call the completion
	// handler.
	if(false == OSAtomicTestAndSet(0, &hasCompleted))
	{
		// Essentially by assinging self to thisHandler we're doing
		// a "[self retain]" (because thisHandler is a strong variable).
		// This is here because self is the delegate of the NSURLConnection
		// and the NSURLConnection object may be the last object with a
		// reference to self.
		//
		// NSURLConnection will drop that reference when it's cancelled and we
		// if that was the last reference to self, self would be freed and
		// badness would ensueTo prevent that from happening, we give the
		// stack local variable thisHandler a reference to self that will only
		// go away when the variable falls out of scope.
		SLHTTPRequest * __strong thisRequest = self;

		[urlConnection cancel];
		[thisRequest->dataCollector abandonData];
		if(thisRequest->completionBlock)
		{
			thisRequest->completionBlock(lastResponse, nil, connectionError);
		}
	}
}

- (NSURLProtectionSpace *) urlProtectionSpace
{
	NSURL *url = [urlRequest URL];

	NSUInteger port = [[url port] intValue];
	if(0 == port)
	{
		port = [url.scheme isEqualToString: @"https"] ? 443 : 80;
	}

	NSURLProtectionSpace *protectionSpace = [[NSURLProtectionSpace alloc] initWithHost: url.host
																				  port: port
																			  protocol: url.scheme
																				 realm: nil
																  authenticationMethod: NSURLAuthenticationMethodDefault];

	return protectionSpace;
}
#pragma mark - NSURLConnectionDelegate

- (void) connectionDidFinishLoading: (NSURLConnection *) connection
{
	// See comment in abortConnectionWithError about OSAtomicTestAndSet
	if(false == OSAtomicTestAndSet(0, &hasCompleted))
	{
		NSError *finishCollectingError = nil;
		NSData *collectedData = [dataCollector finishCollectingData: &finishCollectingError];

		if(self.completionBlock)
		{
			if(!self.completionQueue || self.completionQueue == [NSOperationQueue currentQueue])
			{
				self.completionBlock(lastResponse, collectedData, finishCollectingError);
			} else {
				SLHTTPRequest *thisRequest = self;
				[self.completionQueue addOperationWithBlock: ^{
					thisRequest->completionBlock(thisRequest->lastResponse, collectedData, finishCollectingError);
				}];
			}
		}
	}
}

- (void) connection: (NSURLConnection *) connection
   didFailWithError: (NSError *) error
{
	// See comment in abortConnectionWithError about OSAtomicTestAndSet
	if(false == OSAtomicTestAndSet(0, &hasCompleted))
	{
		NSError *finishCollectingError = nil;
		NSData *collectedData = [dataCollector finishCollectingData: &finishCollectingError];

		if(self.completionBlock)
		{
			if(!self.completionQueue || self.completionQueue == [NSOperationQueue currentQueue])
			{
				self.completionBlock(lastResponse, collectedData, finishCollectingError);
			} else {
				SLHTTPRequest *thisRequest = self;
				[self.completionQueue addOperationWithBlock: ^{
					thisRequest->completionBlock(thisRequest->lastResponse, collectedData, finishCollectingError);
				}];
			}
		}
	}
}

#ifdef DEBUG
- (NSURLRequest *) connection: (NSURLConnection *)connection
			  willSendRequest: (NSURLRequest *)request
			 redirectResponse: (NSURLResponse *)response
{
#if LOG_NETWORK_REQUESTS
	NSLog(@"Issuing async %@ request at URL: %@", [request HTTPMethod], request.URL);
	NSLog(@"Headers: %@", [request allHTTPHeaderFields]);

	if([request HTTPBody])
	{
		NSString *body = [[NSString alloc] initWithData: [request HTTPBody] encoding: NSUTF8StringEncoding];
		NSLog(@"RequestBody of size %d: %@", (unsigned int)[[request HTTPBody] length], body );
	}
#endif

	if(nil != response)
	{
		NSLog(@"Redirection request? %@, %@", request, response);
	}

	return request;
}
#endif

- (void) connection: (NSURLConnection *) connection
 didReceiveResponse: (NSURLResponse *) response
{
	lastResponse = (NSHTTPURLResponse *) response;

	NSError *dataCollectorError = nil;

	// For each response, we reset the network data and begin a new
	// download.
	if(![self.dataCollector beginCollectingData: &dataCollectorError])
	{
		[self abortConnectionWithError: dataCollectorError];
	}
}

-(void) connection: (NSURLConnection *) connection
	didReceiveData: (NSData *) data
{
	NSError *dataCollectorError = nil;

	if(![self.dataCollector appendData: data error: &dataCollectorError])
	{
		[self abortConnectionWithError: dataCollectorError];
	}
}

- (BOOL)				   connection: (NSURLConnection *) connection
canAuthenticateAgainstProtectionSpace: (NSURLProtectionSpace *) requestProtectionSpace
{

	BOOL shouldAuthenticate = NO;

#if LOG_AUTHENTICATION_CHALLENGES
	NSLog(@"Authenicate against space %@, %@, %d, %@", requestProtectionSpace.realm, requestProtectionSpace.host, (unsigned int)requestProtectionSpace.port, requestProtectionSpace.authenticationMethod);
#endif

#if TRUST_INVALID_SSL_CERTS
	// If we have an untrusted server cetificate and we're in debug mode, we
	// go ahead and make the connection
	if([requestProtectionSpace.authenticationMethod isEqual: NSURLAuthenticationMethodServerTrust])
	{
		return YES;
	}
#endif

#if LOG_AUTHENTICATION_CHALLENGES
	NSLog(@"My Protection space is %@, %@, %d, %@", self.urlProtectionSpace.realm, self.urlProtectionSpace.host, (unsigned int)self.urlProtectionSpace.port, self.urlProtectionSpace.authenticationMethod);
#endif

	// Return true if the protection space being challenged matches the
	// protection space of the server.
	shouldAuthenticate = ([requestProtectionSpace.host isEqual: self.urlProtectionSpace.host] &&
						  [requestProtectionSpace.protocol isEqual: self.urlProtectionSpace.protocol] &&
						  [requestProtectionSpace.authenticationMethod isEqual: self.urlProtectionSpace.authenticationMethod] &&
						  requestProtectionSpace.port == self.urlProtectionSpace.port);

#if LOG_AUTHENTICATION_CHALLENGES
	NSLog(@"Telling the caller that we %@ authenticate", shouldAuthenticate ? @"Should" : @"Shound Not");
#endif

	return shouldAuthenticate;
}

- (void)               connection: (NSURLConnection *) connection
didReceiveAuthenticationChallenge: (NSURLAuthenticationChallenge *)challenge
{
#if LOG_AUTHENTICATION_CHALLENGES
	NSLog(@"AuthChallenge %@, %@, %d, %@", challenge.protectionSpace.realm, challenge.protectionSpace.host, (unsigned int)challenge.protectionSpace.port, challenge.protectionSpace.authenticationMethod);
#endif

#if TRUST_INVALID_SSL_CERTS
	// If we have an untrusted server cetificate and we're in debug mode, we
	// go ahead and make the connection
	if([challenge.protectionSpace.authenticationMethod isEqual: NSURLAuthenticationMethodServerTrust])
	{
		[challenge.sender useCredential: [NSURLCredential credentialForTrust: challenge.protectionSpace.serverTrust]
			 forAuthenticationChallenge: challenge];
		[challenge.sender continueWithoutCredentialForAuthenticationChallenge: challenge];
	} else {
#endif

		BOOL shouldAuthenticate = ([challenge.protectionSpace.host isEqual: self.urlProtectionSpace.host] &&
								   [challenge.protectionSpace.protocol isEqual: self.urlProtectionSpace.protocol] &&
								   challenge.protectionSpace.port == self.urlProtectionSpace.port);

		if(shouldAuthenticate && 0 == challenge.previousFailureCount)
		{
			// We're in the right protection space and we've not tried authenticating
			// before... try authenticating now.
			NSURLCredential *requestCredentials = self.urlCredentials;
			if(requestCredentials)
			{
				[challenge.sender useCredential: requestCredentials forAuthenticationChallenge: challenge];
#if LOG_AUTHENTICATION_CHALLENGES
				NSLog(@"Providing credentials %@, %@", requestCredentials.user, requestCredentials.password);
#endif
			} else {
				[challenge.sender cancelAuthenticationChallenge: challenge];
			}
		} else {
			// Tell the caller that we're not interested in pursuing the connection
			[challenge.sender cancelAuthenticationChallenge: challenge];
		}

#if TRUST_INVALID_SSL_CERTS
	}
#endif
}

- (NSCachedURLResponse *) connection: (NSURLConnection *) connection
				   willCacheResponse: (NSCachedURLResponse *) cachedResponse
{
	return nil;
}

#pragma mark - Utility methods

+ (NSError *) errorForFailedHTTPResponse: (NSHTTPURLResponse *) failureResponse
					  additionalUserInfo: (NSDictionary *) additionalInfo
{
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary: @{ NSLocalizedDescriptionKey : kHTTPStatusCodeErrorDomain,
												NSLocalizedFailureReasonErrorKey : [NSHTTPURLResponse localizedStringForStatusCode: [failureResponse statusCode]] }];
	if(additionalInfo)
	{
		[userInfo addEntriesFromDictionary: additionalInfo];
	}

	NSError *httpStatusError = [NSError errorWithDomain: kHTTPStatusCodeErrorDomain code: [failureResponse statusCode] userInfo: userInfo];
	return httpStatusError;
}

@end

BOOL HTTPStatusIndicatesSuccess(NSUInteger statusCode)
{
	return (statusCode >= 200) && (statusCode < 300);
}
