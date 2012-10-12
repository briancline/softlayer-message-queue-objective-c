//
//  SLDataCollectionStrategy.h
//  SLFoundation
//
//  Created by SLDN on 2/3/12.
//  Copyright (c) 2012 SoftLayer Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SLDataCollectionStrategy
- (BOOL) beginCollectingData: (NSError *__autoreleasing *) error;
- (BOOL) appendData: (NSData *) newData error: (NSError *__autoreleasing *) error;
- (NSData *) finishCollectingData: (NSError *__autoreleasing *) finishingError;

// Called when a nework operation is cancelled.
- (void) abandonData;
@end