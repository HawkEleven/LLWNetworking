//
//  BaseAPIManager.m
//  LLWNetworking
//
//  Created by Dalong on 16/6/24.
//  Copyright © 2016年 Dalong. All rights reserved.
//

#import "BaseAPIManager.h"
#import "APIProxy.h"

@interface BaseAPIManager ()

@property (nonatomic, strong) NSMutableArray *requestIdList;

@end

@implementation BaseAPIManager

#pragma mark - life cycle
- (instancetype)init {
    self = [super init];
    if (self) {
        if ([self conformsToProtocol:@protocol(APIManager)]) {
            self.child = (id <APIManager>)self;
        } else {
            NSException *exception = [[NSException alloc] init];
            @throw exception;
        }
    }
    return self;
}

- (void)dealloc {
    [self cancelAllRequests];
    self.requestIdList = nil;
}

#pragma mark - public methods
- (void)cancelAllRequests {
    [[APIProxy sharedInstance] cancelRequestWithRequestIDList:self.requestIdList];
    [self.requestIdList removeAllObjects];
}

- (void)cancelRequestWithRequestId:(NSInteger)requestID {
    [self removeRequestIdWithRequestID:requestID];
    [[APIProxy sharedInstance] cancelRequestWithRequestID:@(requestID)];
}

#pragma mark - calling api
- (void)startRequest {
    NSDictionary *params = [self.paramSource paramsForApi:self];
    [self startRequestWithParams:params];
}

- (void)startRequestWithParams:(NSDictionary *)params {
    NSDictionary *apiParams = [self.child requestWithParams:params];
    NSInteger requestId = 0;
    switch (self.child.requestType) {
        case APIRequestTypeGet:
        {
            requestId = [[APIProxy sharedInstance] callGETWithUrlStr:self.child.requestUrl params:apiParams isCache:self.child.shouldCache success:^(NSDictionary *responseDictory) {
                NSLog(@"response:%@",responseDictory);
                id model = [self.reformer reformerWithData:responseDictory];
                self.fetchedData = model;
                // 回调
                if ([self.delegate respondsToSelector:@selector(managerCallAPIDidSuccess:)]) {
                    [self.delegate managerCallAPIDidSuccess:self];
                }
                
            } fail:^(NSString *error) {
                
            }];
        }
            break;
        case APIRequestTypePost:
        {
            requestId = [[APIProxy sharedInstance] callPOSTWithUrlStr:self.child.requestUrl params:apiParams isCache:self.child.shouldCache success:^(NSDictionary *responseDictory) {
                NSLog(@"response:%@",responseDictory);
                id model = [self.reformer reformerWithData:responseDictory];
                self.fetchedData = model;
                // 回调
                if ([self.delegate respondsToSelector:@selector(managerCallAPIDidSuccess:)]) {
                    [self.delegate managerCallAPIDidSuccess:self];
                }
            } fail:^(NSString *error) {
                
            }];
        }
            break;
        default:
            break;
    }
    [self.requestIdList addObject:@(requestId)];
}

#pragma mark - private methods
- (void)removeRequestIdWithRequestID:(NSInteger)requestId {
    NSNumber *requestIDToRemove = nil;
    for (NSNumber *storedRequestId in self.requestIdList) {
        if ([storedRequestId integerValue] == requestId) {
            requestIDToRemove = storedRequestId;
        }
    }
    if (requestIDToRemove) {
        [self.requestIdList removeObject:requestIDToRemove];
    }
}

#pragma mark - getters and setters
- (NSMutableArray *)requestIdList {
    if (!_requestIdList) {
        _requestIdList = [NSMutableArray array];
    }
    return _requestIdList;
}

@end
