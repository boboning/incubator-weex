//
//  WXCrashAdapterHandler.h
//  Core
//
//  Created by zechang.xzc on 2017/11/16.
//  Copyright © 2017年 taobao. All rights reserved.
//

#import "WXCrashAdapterHandler.h"
#import <BizErrorReporter4iOS/MotuReportAdapteHandler.h>
#import <objc/runtime.h>

#pragma GCC diagnostic ignored "-Wundeclared-selector"
#define BACK_TRACE_LINE_SEPARATOR  @"+__"

static NSString* INSTANCE_ID        = @"instanceId";
static NSString* FRAMEWORK_VERSION  = @"frameWorkVersion";
static NSString* ERROR_CODE         = @"errorCode";
static NSString* PAGE_USER_PATH     = @"pageUserPath";


@implementation WXCrashAdapterHandler

- (void)onJSException:(WXJSExceptionInfo *)exception {
    MotuReportAdapteHandler* handler = [[MotuReportAdapteHandler alloc]init];
    
    AdapterExceptionModule* exceptionModule = [[AdapterExceptionModule alloc] init];
    exceptionModule.customizeBusinessType = @"WEEX_ERROR";
    exceptionModule.aggregationType = ADAPTER_CONTENT;
    
    //统计维度, weex不要按errorcode聚合，没关系，我把url设置到errcode里去
    NSString * bundleUrl = exception.bundleUrl;
    if (bundleUrl == nil) {
        //这个不能为空
        bundleUrl = @"UnKnown";
    }
    exceptionModule.exceptionDetail = bundleUrl;
    NSString* code = [self exceptionUrl:bundleUrl];
    exceptionModule.exceptionCode = code;
    
    NSString * sdkVersion = exception.sdkVersion;
    if (sdkVersion != nil) {
        exceptionModule.exceptionVersion = sdkVersion;
    }
    NSString * exceptionContent = exception.exception;
    if (exceptionContent != nil) {
        exceptionModule.exceptionArg1 = exceptionContent;
    }
    NSString * functionName = exception.functionName;
    if (functionName != nil) {
        exceptionModule.exceptionArg2 = functionName;
    }
    
    NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
    NSMutableDictionary * userInfo = exception.userInfo;
    if (userInfo != nil) {
        [dic addEntriesFromDictionary:userInfo];
    }
    NSString* instanceId = exception.instanceId;
    if (instanceId != nil) {
        [dic setObject:instanceId forKey:INSTANCE_ID];
    }
    NSString * errorCode = exception.errorCode;
    if (errorCode != nil) {
        [dic setObject:errorCode forKey:ERROR_CODE];
    }
    NSString * jsfmVersion = exception.jsfmVersion;
    if (jsfmVersion != nil) {
        [dic setObject:jsfmVersion forKey:FRAMEWORK_VERSION];
    }
    //增加用户轨迹
    NSString * userPage = [self getUserPage];
    if(userPage != nil){
        [dic setObject:userPage forKey:PAGE_USER_PATH];
    }
    exceptionModule.exceptionArgs = dic;
    
    [handler adapterWithExceptionModule:exceptionModule];
    
    // throw js exception to js-bundle via GlobalEvent
    NSDictionary *params = @{@"instanceId":[exception instanceId]?:@"",
                             @"bundleUrl":[exception bundleUrl]?:@"",
                             @"errorCode":[exception errorCode]?:@"",
                             @"functionName":[exception functionName]?:@"",
                             @"exception":[exception exception]?:@"",
                             @"userInfo":[exception userInfo]?:@"",
                             @"jsfmVersion":[exception jsfmVersion]?:@"",
                             @"sdkVersion":[exception sdkVersion]?:@""
                             };
    WXSDKInstance* instance = [WXSDKManager instanceForID: [exception instanceId]];
    if(nil != instance) {
        [instance fireGlobalEvent:@"exception" params:params];
    }
    
}

- (NSString*) exceptionUrl:(NSString*)bundleUrl{
    if ([bundleUrl hasPrefix:@"https:"]) {
        return [bundleUrl substringFromIndex:8];
    } else if([bundleUrl hasPrefix:@"http:"]){
        return [bundleUrl substringFromIndex:7];
    }
    return bundleUrl;
}

- (NSString *)getUserPage
{
    id UTTraceStackClass = objc_getClass("UTTraceStack");
    if (UTTraceStackClass
        && [UTTraceStackClass respondsToSelector: @selector(defaultInstance)])
    {
        id utTraceStack = [UTTraceStackClass performSelector: @selector(defaultInstance)];
        if (utTraceStack && [utTraceStack respondsToSelector: @selector(getTraceStack)]) {
            NSArray *pagesArray = [utTraceStack performSelector: @selector(getTraceStack)];
            if (pagesArray.count)
            {
                NSString *pagesStr = [pagesArray componentsJoinedByString:BACK_TRACE_LINE_SEPARATOR];
                return pagesStr;
            }
        }
    }
    
    return nil;
}

@end
