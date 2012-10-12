//
//  SLHTTPRequest.h
//  SLOpenStackAPI
//
//  Created by SLDN on 10/12/11.
//  Copyright (c) 2011 SoftLayer Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SoftLayerMessaging/SLCancelableOperation.h>

#import "SLDataCollectionStrategy.h"

/* HTTP request completion handler. If error is nil, there were no network
 errors, but you should also check the HTTP statusCode. Any data returned
 by the server will be in the data parameter. */
typedef void (^SLHTTPConnectionHandler)(NSHTTPURLResponse *response, NSData *data, NSError *error);

@interface SLHTTPRequest : NSObject <SLCancelableOperation, NSObject>
@property (strong, readwrite, nonatomic) NSURLCredential *urlCredentials;
@property (strong, nonatomic) id<SLDataCollectionStrategy> dataCollector;

+ (SLHTTPRequest *) requestToLoadNSURLRequest: (NSURLRequest *) urlRequest;

/*! Execute, calling the completion handler on the given queue */
- (void) executeOnQueue: (NSOperationQueue *) queue
	  completionHandler: (SLHTTPConnectionHandler) handler;

/*! Execute synchronously calling the completion handler in-line */
- (void) executeSynchronous: (SLHTTPConnectionHandler) _completionBlock;

/*! Cancel the request (if it's not already complete). This will cause the
 connection handler to be called with an NSError indicating that the
 user cancelled the operation */
- (void) cancel;

/* A utility routine that translates a non-successful status code in an
 NSHTTPURLResponse into an NSError that can be reported elsewhere */
+ (NSError *) errorForFailedHTTPResponse: (NSHTTPURLResponse *) failureResponse
					  additionalUserInfo: (NSDictionary *) additionalInfo;

@end

/*! Utility method that returns true if the given HTTP status code is in the 200s */
extern BOOL HTTPStatusIndicatesSuccess(NSUInteger statusCode);

/*! NSError error domain for HTTP status codes created by errorForFailedHTTPResponse: */
extern NSString * const kHTTPStatusCodeErrorDomain;

/*! Select HTTP 1.1 status codes */
#define kHTTPStatusCodeCreated	 201
#define kHTTPStatusCodeAccepted  202
#define kHTTPStatusCodeNoContent 204
#define kHTTPStatusCodeNotFound  404