//
//  SLMessagingMessage.h
//  SLMessaging_iOS
//
//  Created by SLDN on 9/26/12.
//  Copyright (c) 2012 SoftLayer Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SoftLayerMessaging/SLCancelableOperation.h>

@class SLJSONRestResource;

@interface SLMessagingMessage : NSObject

- (id) initWithRestResource: (SLJSONRestResource *) restResource
				 properties: (NSDictionary *) properties;

@property (readonly, nonatomic) NSString *messageID;
@property (readonly, nonatomic) NSString *body;
@property (readonly, nonatomic) NSDate *initialEntryTime;

/* Delete this message from it's current messaging queue */
- (id<SLCancelableOperation>) deleteMessageWithQueue: (NSOperationQueue *) completionQueue
								   completionHandler: (void (^)(BOOL succeeded, NSError *error)) completionHandler;
@end
