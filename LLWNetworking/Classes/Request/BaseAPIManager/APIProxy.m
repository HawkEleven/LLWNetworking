//
//  APIProxy.m
//  网络层设计
//
//  Created by Dalong on 16/7/5.
//  Copyright © 2016年 Dalong. All rights reserved.
//

#import "APIProxy.h"
#import "AFNetworking.h"
#import <YYCache/YYCache.h>



static NSString * const HttpCache = @"HttpCache";

typedef NS_ENUM(NSInteger, RequestType) {
    RequestTypeGet,
    RequestTypePost,
    RequestTypeUpLoad,//单个上传
    RequestTypeMultiUpload,//多个上传
    RequestTypeDownload
};

@interface APIProxy ()

@property (nonatomic, strong) NSMutableDictionary *dispatchTable;
@property (nonatomic, strong) NSNumber *recordedRequestId;

//AFNetworking stuff
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@end

@implementation APIProxy

#pragma mark - life cycle
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static APIProxy *sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[APIProxy alloc] init];
    });
    return sharedInstance;
}

#pragma mark - public methods
- (NSInteger)callGETWithUrlStr:(NSString *)urlStr params:(NSDictionary *)params isCache:(BOOL)isCache success:(SuccessBlock)success fail:(FailureBlock)failure {
    NSString *cacheKey = [self cacheKeyWithUrl:urlStr params:params];
    NSNumber *requestId = [self requestWithUrl:urlStr params:params requestType:RequestTypeGet isCache:isCache cacheKey:cacheKey success:^(NSDictionary *responseDictory) {
        if (success) {
            success(responseDictory);
        }
    } fail:^(NSString *error) {
        if (failure) {
            failure(error);
        }
    }];
    return [requestId integerValue];
}

- (NSInteger)callPOSTWithUrlStr:(NSString *)urlStr params:(NSDictionary *)params isCache:(BOOL)isCache success:(SuccessBlock)success fail:(FailureBlock)failure {
    NSString *cacheKey = [self cacheKeyWithUrl:urlStr params:params];
    NSNumber *requestId = [self requestWithUrl:urlStr params:params requestType:RequestTypePost isCache:isCache cacheKey:cacheKey success:^(NSDictionary *responseDictory) {
        if (success) {
            success(responseDictory);
        }
    } fail:^(NSString *error) {
        if (failure) {
            failure(error);
        }
    }];
    return [requestId integerValue];
}

- (void)cancelRequestWithRequestID:(NSNumber *)requestID {
    NSURLSessionDataTask *requestOperation = self.dispatchTable[requestID];
    [requestOperation cancel];
    [self.dispatchTable removeObjectForKey:requestID];
}

- (void)cancelRequestWithRequestIDList:(NSArray *)requestIDList {
    for (NSNumber *requestId in requestIDList) {
        [self cancelRequestWithRequestID:requestId];
    }
}

#pragma mark - private methods
- (NSNumber *)requestWithUrl:(NSString *)url params:(NSDictionary *)params requestType:(RequestType)requestType isCache:(BOOL)isCache cacheKey:(NSString *)cacheKey success:(SuccessBlock)success fail:(FailureBlock)failure {
    
    // 设置YYCache属性
    YYCache *cache = [[YYCache alloc] initWithName:HttpCache];
    cache.memoryCache.shouldRemoveAllObjectsOnMemoryWarning = YES;
    cache.memoryCache.shouldRemoveAllObjectsWhenEnteringBackground = YES;
    
    id cacheData;
    
    if (isCache) {
        // 根据网址从Cache中取数据
        cacheData = [cache objectForKey:cacheKey];
        if (cacheData != 0) {
            // 将数据统一处理
            [self returnDataWithRequestData:cacheData success:^(NSDictionary *responseDictory) {
                NSLog(@"缓存数据\n\n     %@     \n\n",responseDictory);
                if (success) {
                    success(responseDictory);
                }
            } failure:^(NSString *error) {
                if (failure) {
                    failure(error);
                }
            }];
        }
    }
    
    // 网络判断
    if (![self requestBeforeJudgeConnect]) {
        if (failure) {
            failure(NETWORKERROR);
            NSLog(@"没有网络");
        }
        return nil;
    }
    
    // 发请求
    __block NSURLSessionDataTask *dataTask = nil;
    switch (requestType) {
        case RequestTypeGet:
        {
            dataTask = [self.sessionManager GET:url parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
                
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [self dealWithResponseObject:responseObject cacheData:cacheData isCache:isCache cache:cache cacheKey:cacheKey success:^(NSDictionary *responseDictory) {
                    if (success) {
                        success(responseDictory);
                    }
                } failure:^(NSString *error) {
                    if (failure) {
                        failure(error);
                    }
                }];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                if (failure) {
                    failure(NETWORKERROR);
                }
            }];
        }
            break;
        case RequestTypePost:
        {
            dataTask = [self.sessionManager POST:url parameters:params progress:^(NSProgress * _Nonnull uploadProgress) {
                
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [self dealWithResponseObject:responseObject cacheData:cacheData isCache:isCache cache:cache cacheKey:cacheKey success:^(NSDictionary *responseDictory) {
                    if (success) {
                        success(responseDictory);
                    }
                } failure:^(NSString *error) {
                    if (failure) {
                        failure(error);
                    }
                }];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                if (failure) {
                    failure(NETWORKERROR);
                }
            }];
        }
            break;
            
        default:
            break;
    }
    NSNumber *requestId = @([dataTask taskIdentifier]);
    self.dispatchTable[requestId] = dataTask;
    [dataTask resume];
    
    return requestId;
}

#pragma mark - 统一处理请求到的数据
- (void)dealWithResponseObject:(NSData *)responseData cacheData:(id)cacheData isCache:(BOOL)isCache cache:(YYCache *)cache cacheKey:(NSString *)cacheKey success:(SuccessBlock)success failure:(FailureBlock)failure {
    NSString *dataString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    dataString = [self deleteSpecialCodeWithStr:dataString];
    NSData *requestData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    
    if (isCache) {
        [cache setObject:requestData forKey:cacheKey];
    }
    // 如果不缓存 或者 数据不同 从网络请求
    if (!isCache || ![cacheData isEqual:requestData]) {
        [self returnDataWithRequestData:requestData success:^(NSDictionary *responseDictory) {
            NSLog(@"网络数据\n\n     %@     \n\n",responseDictory);
            if (success) {
                success(responseDictory);
            }
        } failure:^(NSString *error) {
            if (failure) {
                failure(error);
            }
        }];
    }
}

- (NSString *)cacheKeyWithUrl:(NSString *)url params:(NSDictionary *)params {
    // 处理中文和空格问题
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSString *cacheKey = [self urlDictToStringWithUrlStr:url WithDict:params];
    return cacheKey;
}

- (NSString *)urlDictToStringWithUrlStr:(NSString *)urlString WithDict:(NSDictionary *)parameters {
    if (!parameters) {
        return urlString;
    }
    
    NSMutableArray *parts = [NSMutableArray array];
    
    [parameters enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        //字符串处理
        key=[NSString stringWithFormat:@"%@",key];
        obj=[NSString stringWithFormat:@"%@",obj];
        
        //接收key
        NSString *finalKey = [key stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        //接收值
        NSString *finalValue = [obj stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        
        
        NSString *part =[NSString stringWithFormat:@"%@=%@",finalKey,finalValue];
        
        [parts addObject:part];
        
    }];
    
    NSString *queryString = [parts componentsJoinedByString:@"&"];
    
    queryString = queryString.length!=0 ? [NSString stringWithFormat:@"?%@",queryString] : @"";
    
    NSString *pathStr = [NSString stringWithFormat:@"%@%@",urlString,queryString];
    
    return pathStr;
    
}

#pragma mark  网络判断
- (BOOL)requestBeforeJudgeConnect {
    struct sockaddr zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sa_len = sizeof(zeroAddress);
    zeroAddress.sa_family = AF_INET;
    SCNetworkReachabilityRef defaultRouteReachability =
    SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;
    BOOL didRetrieveFlags =
    SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
    if (!didRetrieveFlags) {
        printf("Error. Count not recover network reachability flags\n");
        return NO;
    }
    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
    BOOL isNetworkEnable  =(isReachable && !needsConnection) ? YES : NO;
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [UIApplication sharedApplication].networkActivityIndicatorVisible =isNetworkEnable;/*  网络指示器的状态： 有网络 ： 开  没有网络： 关  */
//    });
    return isNetworkEnable;
}

#pragma mark - 根据返回的数据进行统一的格式处理 requestData网络或者是缓存的数据
- (void)returnDataWithRequestData:(NSData *)requestData success:(SuccessBlock)success failure:(FailureBlock)failure {
    id myResult = [NSJSONSerialization JSONObjectWithData:requestData options:NSJSONReadingMutableContainers error:nil];
    // 判断是否为字典
    if ([myResult isKindOfClass:[NSDictionary class]]) {
        NSDictionary *requestDic = (NSDictionary *)myResult;
        if ([requestDic[@"errCode"] isEqualToNumber:@0]) { // 根据后台返回信息处理
            if (success) {
                success(requestDic);
            }
        } else {
            if (failure) {
                failure(requestDic[@"errMsg"]);
            }
        }
    }
}

#pragma mark -- 处理json格式的字符串中的换行符、回车符
- (NSString *)deleteSpecialCodeWithStr:(NSString *)str {
    NSString *string = [str stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"(" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@")" withString:@""];
    return string;
}

#pragma mark - getters and setters
- (NSMutableDictionary *)dispatchTable {
    if (!_dispatchTable) {
        _dispatchTable = [[NSMutableDictionary alloc] init];
    }
    return _dispatchTable;
}

- (AFHTTPSessionManager *)sessionManager {
    if (!_sessionManager) {
        _sessionManager = [AFHTTPSessionManager manager];
        _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        _sessionManager.securityPolicy.allowInvalidCertificates = YES;
        _sessionManager.securityPolicy.validatesDomainName = NO;
        _sessionManager.responseSerializer.acceptableContentTypes=[NSSet setWithObjects:@"application/json",@"text/json",@"text/javascript",@"text/html", nil];
        _sessionManager.requestSerializer.timeoutInterval = 10.0f;
    }
    return _sessionManager;
}

@end
