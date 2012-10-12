//
//  SLJSONRestClient.m
//  SLMessaging_iOS
//
//  Created by SLDN on 9/11/12.
//  Copyright (c) 2012 SoftLayer Technologies, Inc. All rights reserved.
//
#import "SLJSONRestResource.h"
#import "SLHTTPRequest.h"

NSString * const kJSONContentType = @"application/json";

@interface SLJSONRestResource ()
@property (strong, readwrite, nonatomic) NSURL *resourceURL;
@end

@implementation SLJSONRestResource

- (id) initWithResourceURL: (NSURL *) endpointBaseURL
{
    self = [super init];
    if (self) {
        self.resourceURL = endpointBaseURL;
    }

    return self;
}

- (SLJSONRestResource *) resourceAtRelativePath: (NSString *) relativePath
{
	NSURL *newResourceURL = self.resourceURL;

	if(relativePath && [relativePath length] > 0)
	{
		newResourceURL = [self.resourceURL URLByAppendingPathComponent: relativePath];
	}

	return [[SLJSONRestResource alloc] initWithResourceURL: newResourceURL];
}

- (id<SLCancelableOperation>)  deleteWithQueue: (NSOperationQueue *) completionQueue
							 completionHandler: (SLJSONRestClientCompletionHandler) completionBlock
{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: self.resourceURL];
	request.HTTPMethod = @"DELETE";
	[request addValue: kJSONContentType forHTTPHeaderField: @"Accept"];

	return [self runRequest: request queue: completionQueue completionHandler: completionBlock];
}


- (id<SLCancelableOperation>) getWithQueue: (NSOperationQueue *) completionQueue
						 completionHandler: (SLJSONRestClientCompletionHandler) completionBlock
{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: self.resourceURL];
	request.HTTPMethod = @"GET";
	[request addValue: kJSONContentType forHTTPHeaderField: @"Accept"];

	return [self runRequest: request queue: completionQueue completionHandler: completionBlock];
}

- (id<SLCancelableOperation>) postData: (NSData *) postBody
								 queue: (NSOperationQueue *) completionQueue
					 completionHandler: (SLJSONRestClientCompletionHandler) completionBlock
{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: self.resourceURL];
	request.HTTPMethod = @"POST";
	[request setHTTPBody: postBody];
	[request addValue: kJSONContentType forHTTPHeaderField: @"Accept"];
	[request addValue: kJSONContentType forHTTPHeaderField: @"Content-Type"];

	return [self runRequest: request queue: completionQueue completionHandler: completionBlock];
}

- (id<SLCancelableOperation>)  putData: (NSData *) putBody
								 queue: (NSOperationQueue *) completionQueue
					 completionHandler: (SLJSONRestClientCompletionHandler) completionBlock
{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: self.resourceURL];
	request.HTTPMethod = @"PUT";
	[request setHTTPBody: putBody];
	[request addValue: kJSONContentType forHTTPHeaderField: @"Accept"];
	[request addValue: kJSONContentType forHTTPHeaderField: @"Content-Type"];

	return [self runRequest: request queue: completionQueue completionHandler: completionBlock];
}

#pragma mark -- Private methods

- (SLHTTPRequest *) runRequest: (NSMutableURLRequest *) urlRequest
						 queue: (NSOperationQueue *) completionQueue
			 completionHandler: (SLJSONRestClientCompletionHandler) completionBlock
{
	if(_headers)
	{
		[_headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			[urlRequest addValue: obj forHTTPHeaderField: key];
		}];
	}

	SLHTTPRequest *httpRequest = [SLHTTPRequest requestToLoadNSURLRequest: urlRequest];
	[httpRequest executeOnQueue: completionQueue
			  completionHandler: ^(NSHTTPURLResponse *response, NSData *data, NSError *networkError) {
				  if(!networkError)
				  {
					  if(HTTPStatusIndicatesSuccess(response.statusCode))
					  {
						  NSError *jsonParseError = nil;
						  id jsonObject = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingAllowFragments error: &jsonParseError];
						  if(jsonObject)
						  {
							  completionBlock(jsonObject, [response allHeaderFields], nil);
						  } else {
							  completionBlock(nil, [response allHeaderFields], jsonParseError);
						  }
					  } else {
						  NSError *statusError = [SLHTTPRequest errorForFailedHTTPResponse: response additionalUserInfo: nil];
						  completionBlock(nil, [response allHeaderFields], statusError);
					  }
				  } else {
					  completionBlock(nil, [response allHeaderFields], networkError);
				  }
			  }];

	return httpRequest;
}
@end
