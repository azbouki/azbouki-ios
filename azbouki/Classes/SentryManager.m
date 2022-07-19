//
//  SentryManager.m
//  AzboukiClient
//
//  Created by Dermendzhiev, Teodor on 18.05.22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "SentrySDK.h"
#import "SentryManager.h"

@interface SentrySDK(Private)
@property (class) SentryHub *currentHub;
@end

@interface SentryClient(Private)
- (SentryEvent *_Nullable)prepareEvent:(SentryEvent *)event
                             withScope:(SentryScope *)scope
                alwaysAttachStacktrace:(BOOL)alwaysAttachStacktrace;
@end

@implementation SentryManager

+(SentryHub*) getSentryHub {
    return [SentrySDK currentHub];
}

+ (SentryEvent *_Nullable)prepareEvent:(SentryEvent *)event
                             withScope:(SentryScope *)scope
                alwaysAttachStacktrace:(BOOL)alwaysAttachStacktrace {
   return [[[SentrySDK currentHub] getClient] prepareEvent:event withScope:scope alwaysAttachStacktrace:alwaysAttachStacktrace];
}

@end
