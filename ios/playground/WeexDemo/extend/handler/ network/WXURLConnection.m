//
//  WXURLConnection.m
//  Pods
//
//  Created by bobning on 17/2/9.
//
//

#import "WXURLConnection.h"

@implementation WXURLConnection

- (instancetype)initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately {
    if (self = [super initWithRequest:request delegate:delegate startImmediately:startImmediately]) {
        // if startImmediately is NO, then schedule to current run loop for common modes
        if (!startImmediately) {
            [self scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        }
    }
    return self;
}
@end
