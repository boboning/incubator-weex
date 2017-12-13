//
//  WXURLConnection.h
//  Pods
//
//  Created by bobning on 17/2/9.
//
//

#import <Foundation/Foundation.h>
#import <WeexSDK/WeexSDK.h>

@interface WXURLConnection : NSURLConnection

@property (nonatomic, strong)   id<WXResourceRequestDelegate> requestDelegate;

@property (nonatomic, strong)   NSHTTPURLResponse *response;

@end
