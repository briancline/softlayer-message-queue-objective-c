//
//  NSError+SLUserCancelled.h
//  SLFoundation
//
//  Created by SLDN on 10/17/11.
//  Copyright (c) 2011 SoftLayer Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (SLUserCancelled)

/*! Return an NSError representing the "User Cancelled" condition */
+ (NSError *) sl_userCancelledError;

/*! Return true if this error is a "User Cancelled" error */
- (BOOL) sl_isUserCancelledError;
@end
