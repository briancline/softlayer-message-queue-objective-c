//
//  SLJSONRestResource.h
//  SLMessaging_iOS
//
//  Created by SLDN on 9/11/12.
//  Copyright (c) 2012 SoftLayer Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SoftLayerMessaging/SLCancelableOperation.h>

typedef void (^SLJSONRestClientCompletionHandler)(id JSONResult, NSDictionary *responseHeaders, NSError *error);

@interface SLJSONRestResource : NSObject

/*! The URL of the given rest resource */
@property (strong, readonly, nonatomic) NSURL *resourceURL;

/*! Additional headers sent along with each request made by the resource */
@property (strong, readwrite, nonatomic) NSDictionary *headers;

- (id) initWithResourceURL: (NSURL *) endpointBaseURL;

/*! Return a new Rest resource that is at a relative path location to this
 rest resource (note that headers are NOT transferred to the new resource
 by default */
- (SLJSONRestResource *) resourceAtRelativePath: (NSString *) relativePath;


/*! Issue an HTTP 'DELETE' request to the resource */
- (id<SLCancelableOperation>)  deleteWithQueue: (NSOperationQueue *) completionQueue
							 completionHandler: (SLJSONRestClientCompletionHandler) completionBlock;

/*! Issue an HTTP 'GET' request for the resource */
- (id<SLCancelableOperation>) getWithQueue: (NSOperationQueue *) completionQueue
						 completionHandler: (SLJSONRestClientCompletionHandler) completionBlock;

/*! Issue an HTTP 'POST' to the resource with the given HTTP message body */
- (id<SLCancelableOperation>) postData: (NSData *) postBody
								 queue: (NSOperationQueue *) completionQueue
					 completionHandler: (SLJSONRestClientCompletionHandler) completionBlock;

/*! Issue an HTTP 'PUT' request to the resource */
- (id<SLCancelableOperation>)  putData: (NSData *) putBody
								 queue: (NSOperationQueue *) completionQueue
					 completionHandler: (SLJSONRestClientCompletionHandler) completionBlock;

@end

/* Convenient constant for "ContentType" */
NSString * const kJSONContentType;