//
//  NSArray+BlockOperations.m
//  SLFoundation
//
//  Created by SLDN on 11/2/11.
//  Copyright (c) 2011 SoftLayer Technologies, Inc.. All rights reserved.
//

#import "NSArray+BlockOperations.h"

@implementation NSArray (SL_BlockOperations)

- (NSArray *) arrayByCollectingElements: (SLArrayOpElementBlock) block
{
	NSMutableArray *collectedResults = [NSMutableArray arrayWithCapacity: self.count];
	[self enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
		id transformedElement = block(obj, idx);
		[collectedResults addObject: transformedElement ? transformedElement : [NSNull null]];
	}];

	return collectedResults;
}

- (NSArray *) arrayByCollectingElementsWithOptions: (SLArrayCollectionOptions) options
										usingBlock: (SLArrayOpElementBlock) block;
{
	NSMutableArray *collectedResults = [NSMutableArray arrayWithCapacity: self.count];
	[self enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
		id transformedElement = block(obj, idx);

		if((options & kSLArrayCollectionRemoveNilObjects) > 0)
		{
			if(nil != transformedElement)
			{
				[collectedResults addObject: transformedElement];
			}
		} else {
			[collectedResults addObject: transformedElement ? transformedElement : [NSNull null]];
		}
	}];

	return collectedResults;
}

- (NSUInteger) numberOfElementsPassingTest: (SLArrayOpLogicgalBlock) predicate
{
	__block NSUInteger numElements = 0;
	[self enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
		if(predicate(obj, idx))
		{
			++numElements;
		}
	}];
	return numElements;
}

- (NSArray *) arrayWithElementsPassingTest: (SLArrayOpLogicgalBlock) predicate
{
	NSMutableArray *collectedResults = [NSMutableArray arrayWithCapacity: self.count];
	[self enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
		if(predicate(obj, idx))
		{
			[collectedResults addObject: obj];
		}
	}];

	return collectedResults;
}

- (void) partitionIntoElementsPassingTest: (NSArray **) passingElementsArray
						   andFailingTest: (NSArray **) failingElementsArray
								usingTest: (SLArrayOpLogicgalBlock) elementTest
{
	NSMutableArray *elementsPassingTest, *elementsFailingTest;

	if(passingElementsArray)
	{
		elementsPassingTest = [NSMutableArray array];
		*passingElementsArray = elementsPassingTest;
	}

	if(failingElementsArray)
	{
		elementsFailingTest = [NSMutableArray array];
		*failingElementsArray = elementsFailingTest;
	}

	[self enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
		if(elementTest(obj, idx))
		{
			[elementsPassingTest addObject: obj];
		} else {
			[elementsFailingTest addObject: obj];
		}
	}];
}

@end
