//
//  NSURL+SLQueryString.h
//  SLMessaging_iOS
//
//  Created by SLDN on 10/3/12.
//  Copyright (c) 2012 SoftLayer Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (SLQueryString)
/*! return a new URL formed by appending the given query string to this URL */
- (NSURL *) URLByAppendingQuery: (NSString *) queryString;
@end
