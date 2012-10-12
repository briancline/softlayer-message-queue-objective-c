//
//  SLRAMBasedDataStrategy.m
//  SLOpenStackAPI
//
//  Created by SLDN on 10/13/11.
//  Copyright (c) 2011 SoftLayer Technologies, Inc. All rights reserved.
//

#import "SLRAMBasedDataStrategy.h"

@interface SLRAMBasedDataStrategy ()
@property (strong, nonatomic) NSMutableData *collectedData;
@end

@implementation SLRAMBasedDataStrategy

@synthesize collectedData;

- (BOOL) beginCollectingData: (NSError **) error
{
#pragma unused (error)
	self.collectedData = [NSMutableData data];

	return YES;
}

- (BOOL) appendData: (NSData *) newData error: (NSError **) error

{
#pragma unused (error)
	if(!self.collectedData)
	{
		self.collectedData = [NSMutableData data];
	}

	if(self.collectedData)
	{
		[self.collectedData appendData: newData];
	}

	return YES;
}

- (NSData *) finishCollectingData: (NSError *__autoreleasing *) finishingError
{
	return self.collectedData;
}

- (void) abandonData
{
	/* do nothing */
}
@end
