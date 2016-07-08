//
//  BaseAPIManager.h
//  LLWNetworking
//
//  Created by Dalong on 16/6/24.
//  Copyright © 2016年 Dalong. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BaseAPIManager;
/** API回调 */
@protocol BaseAPIManagerCallBackDelegate <NSObject>

@required
- (void)managerCallAPIDidSuccess:(BaseAPIManager *)manager;
- (void)managerCallAPIDidFailed:(BaseAPIManager *)manager;

@end

/** 让manager能够获取调用API所需要的数据 */
@protocol APIManagerParamSource <NSObject>

@required
- (NSDictionary *)paramsForApi:(BaseAPIManager *)manager;

@end

/** 返回数据转换 */
@protocol APIManagerDataReformer <NSObject>

@required
- (id)reformerWithData:(NSDictionary *)data;

@end

typedef NS_ENUM(NSInteger, APIRequestType) {
    APIRequestTypeGet,
    APIRequestTypePost,
    APIRequestTypeUpload,
    APIRequestTypeDownload
};

/** APIBaseManager的派生类必须符合这些protocal */
@protocol APIManager <NSObject>

@required
- (NSString *)requestUrl;
- (APIRequestType)requestType;
- (NSDictionary *)requestWithParams:(NSDictionary *)params;
- (BOOL)shouldCache;

@end

@interface BaseAPIManager : NSObject

@property (nonatomic, weak) id<BaseAPIManagerCallBackDelegate> delegate;
@property (nonatomic, weak) id<APIManagerParamSource> paramSource;
@property (nonatomic, weak) id<APIManagerDataReformer> reformer;
@property (nonatomic, weak) NSObject<APIManager> *child;
@property (nonatomic, strong) id fetchedData;
/** 加载更多 */
@property (nonatomic, assign) NSInteger pageNum;

- (void)startRequest;
- (void)cancelAllRequests;
- (void)cancelRequestWithRequestId:(NSInteger)requestID;

@end
