//
//  NSError+SLUserCancelled.m
//  SLFoundation
//
//  Created by SLDN on 10/17/11.
//  Copyright (c) 2011 SoftLayer Technologies, Inc. All rights reserved.
//

#import "NSError+SLUserCancelled.h"

@implementation NSError (SLUserCancelled)

+ (NSError *) sl_userCancelledError
{
	return [NSError errorWithDomain: NSCocoaErrorDomain code: NSUserCancelledError userInfo: nil];
}

- (BOOL) sl_isUserCancelledError
{
	return [self.domain isEqualToString: NSCocoaErrorDomain] && (self.code == NSUserCancelledError);
}
@end
