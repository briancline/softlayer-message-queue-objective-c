//
//  SLRAMBasedDataStrategy.h
//  SLOpenStackAPI
//
//  Created by SLDN on 10/13/11.
//  Copyright (c) 2011 SoftLayer Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SLDataCollectionStrategy.h"

/*! A data collection strategy that simply grabs the data and stores it in 
 main memory */
@interface SLRAMBasedDataStrategy : NSObject <SLDataCollectionStrategy>

- (BOOL) beginCollectingData: (NSError **) error;
- (BOOL) appendData: (NSData *) newData error: (NSError **) error;
- (NSData *) finishCollectingData: (NSError *__autoreleasing *) finishingError;

@end
