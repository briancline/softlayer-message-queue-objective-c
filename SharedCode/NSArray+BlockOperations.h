//
//  NSArray+BlockOperations.h
//  SLFoundation
//
//  Created by SLDN on 11/2/11.
//  Copyright (c) 2011 SoftLayer Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef BOOL (^SLArrayOpLogicgalBlock)(id obj, NSUInteger idx);
typedef id (^SLArrayOpElementBlock)(id obj, NSUInteger idx);

typedef enum {
	kSLArrayCollectionRemoveNilObjects = 1 << 0
} SLArrayCollectionOptions;

@interface NSArray (SL_BlockOperations)

/*! Enumerate the items in the array passing each to the block.  Create a new
 array by collecting the elements returned by the block into an array */
- (NSArray *) arrayByCollectingElements: (SLArrayOpElementBlock) block;

/*! Like arrayByCollectingElements, but allows the removal of objects for which
 the block returns nil to be excluded from the resulting array */
- (NSArray *) arrayByCollectingElementsWithOptions: (SLArrayCollectionOptions) options
										usingBlock: (SLArrayOpElementBlock) block;

/*! Returns the number of elements in the array that return YES when passed 
 through the predicate block */
- (NSUInteger) numberOfElementsPassingTest: (SLArrayOpLogicgalBlock) predicate;

/*! Collect the elements of the array for which the given block returns YES */
- (NSArray *) arrayWithElementsPassingTest: (SLArrayOpLogicgalBlock) predicate;

/*! Separate the elements of the array into two separate arrays based on 
	whether they are accepted, or rejected by the given test */
- (void) partitionIntoElementsPassingTest: (NSArray **) passingElementsArray
						   andFailingTest: (NSArray **) failingElementsArray
								usingTest: (SLArrayOpLogicgalBlock) elementTest;
@end
