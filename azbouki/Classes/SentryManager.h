//
//  SentryManager.h
//  AzboukiClient
//
//  Created by Dermendzhiev, Teodor on 18.05.22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Sentry;

NS_ASSUME_NONNULL_BEGIN

@interface SentryManager : NSObject

+ (SentryHub*) getSentryHub;

+ (SentryEvent *_Nullable)prepareEvent:(SentryEvent *)event
                             withScope:(SentryScope *)scope
                alwaysAttachStacktrace:(BOOL)alwaysAttachStacktrace;

@end

NS_ASSUME_NONNULL_END
