//
//  NSURL+SLQueryString.m
//  SLMessaging_iOS
//
//  Created by SLDN on 10/3/12.
//  Copyright (c) 2012 SoftLayer Technologies, Inc. All rights reserved.
//

#import "NSURL+SLQueryString.h"

@implementation NSURL (SLQueryString)
- (NSURL *) URLByAppendingQuery: (NSString *) queryString
{
	if(!queryString || 0 == [queryString length])
		return self;

	NSString *newString = [NSString stringWithFormat: @"%@%@%@", [self absoluteString], [self query] ? @"&" : @"?", queryString];
	return [NSURL URLWithString: newString];
}
@end
