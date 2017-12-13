//
//  WXNetworkHandler.m
//  Pods
//
//  Created by bobning on 17/1/17.
//
//

#import "WXNetworkHandler.h"
#import "WXURLConnection.h"

@implementation WXNetworkHandler

- (void)sendRequest:(WXResourceRequest *)request withDelegate:(id<WXResourceRequestDelegate>)delegate
{
    //网络请求前，先检查zcache，如果命中则直接返回
    NSData *zcache = nil;
    
    if (zcache && [zcache length] > 0) {
//        NSHTTPURLResponse * response = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type":[WVURL getMimeTypeWithPath:request.URL.path], @"Content-Length":[NSString stringWithFormat:@"%zd",[zcache length]], @"X-RequestType":@"PackageApp", @"X-WV-PkgName":@"PackageApp"}];
//        [delegate request:request didReceiveResponse:(WXResourceResponse *)response];
//        [delegate request:request didReceiveData:zcache];
//        [delegate requestDidFinishLoading:request];
        return;
    }
    
    //正常请求
    if (request.type == WXResourceTypeMainBundle) {
        request.timeoutInterval = 30;
        [request setValue:@"weex" forHTTPHeaderField:@"f-refer"];
        [request setValue:[self generateLanguageString] forHTTPHeaderField:@"Accept-Language"];
    }
    
    WXURLConnection *connect = [[WXURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    connect.requestDelegate = delegate;
    
    [connect start];
}

- (NSString*)generateLanguageString {
    // 语言编码 zh
    NSLocale *currentLocale = [NSLocale currentLocale];
    NSString *languageCode = [currentLocale objectForKey:NSLocaleLanguageCode];
    
    // 系统语言 zh-Hans
    NSArray *arLanguages = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
    NSString *strLang = [arLanguages objectAtIndex:0];
    
    // zh-Hans,zh;q=0.8,en-US;q=0.5,en;q=0.3
    NSMutableString *ret = [NSMutableString string];
    [ret appendString:strLang];
    [ret appendString:@","];
    [ret appendString:languageCode];
    [ret appendString:@";q=0.8,en-US;q=0.5,en;q=0.3"];
    
    return ret;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection  didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if (![connection isKindOfClass:[WXURLConnection class]]) {
        [connection cancel];
        return;
    }
    
    WXURLConnection *connect = (WXURLConnection *)connection;
    [connect.requestDelegate request:(WXResourceRequest *)connect.originalRequest didSendData:bytesWritten totalBytesToBeSent:totalBytesExpectedToWrite];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if (![connection isKindOfClass:[WXURLConnection class]]) {
        [connection cancel];
        return;
    }
    
    WXURLConnection *connect = (WXURLConnection *)connection;
    WXResourceRequest *originalRequest = (WXResourceRequest *)connect.originalRequest;
    if (originalRequest.type == WXResourceTypeMainBundle) {
        connect.response = (NSHTTPURLResponse *)response;
    }
    
    [connect.requestDelegate request:(WXResourceRequest *)connect.originalRequest didReceiveResponse:(WXResourceResponse *)response];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (![connection isKindOfClass:[WXURLConnection class]]) {
        [connection cancel];
        return;
    }
    
    WXURLConnection *connect = (WXURLConnection *)connection;
    [connect.requestDelegate request:(WXResourceRequest *)connect.originalRequest didReceiveData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (![connection isKindOfClass:[WXURLConnection class]]) {
        [connection cancel];
        return;
    }
    
    WXURLConnection *connect = (WXURLConnection *)connection;
    [connect.requestDelegate request:(WXResourceRequest *)connect.originalRequest didFailWithError:error];
    [connect cancel];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (![connection isKindOfClass:[WXURLConnection class]]) {
        [connection cancel];
        return;
    }
    
    WXURLConnection *connect = (WXURLConnection *)connection;
    WXResourceRequest *originalRequest = (WXResourceRequest *)connect.originalRequest;
    if (originalRequest.type == WXResourceTypeMainBundle) {
        if (((NSHTTPURLResponse *)connect.response).statusCode != 200) {
            NSError *error = [NSError errorWithDomain:WX_ERROR_DOMAIN
                                                 code:((NSHTTPURLResponse *)connect.response).statusCode
                                             userInfo:@{@"message":@"response stataCode is not 200."}];
            [connect.requestDelegate request:(WXResourceRequest *)connect.originalRequest didFailWithError:error];
            [connect cancel];
            return;
        }
    }
    
    [connect.requestDelegate requestDidFinishLoading:(WXResourceRequest *)connect.originalRequest];
    [connect cancel];
}
@end
