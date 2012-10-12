//
//  SLCancelableOperation.h
//  SLFoundation
//
//  Created by SLDN on 11/9/11.
//  Copyright (c) 2011 SoftLayer Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SLCancelableOperation <NSObject>
- (void) cancel;
@end
