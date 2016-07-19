//
//  APIProxy.h
//  网络层设计
//
//  Created by Dalong on 16/7/5.
//  Copyright © 2016年 Dalong. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void(^SuccessBlock)(NSDictionary *responseDictory);
typedef void(^FailureBlock)(NSString *error);

@interface APIProxy : NSObject

+ (instancetype)sharedInstance;

//- (NSInteger)callGETWithParams:(NSDictionary *)params methodName:(NSString *)methodName success:(AXCallBack)success fail:(AXCallBack)fail;
//- (NSInteger)callPOSTWithParams:(NSDictionary *)params serviceIdentifier:(NSString *)servieIdentifier methodName:(NSString *)methodName success:(AXCallBack)success fail:(AXCallBack)fail;

- (NSInteger)callGETWithUrlStr:(NSString *)urlStr params:(NSDictionary *)params isCache:(BOOL)isCache success:(SuccessBlock)success fail:(FailureBlock)failure;
- (NSInteger)callPOSTWithUrlStr:(NSString *)urlStr params:(NSDictionary *)params isCache:(BOOL)isCache success:(SuccessBlock)success fail:(FailureBlock)failure;

- (void)cancelRequestWithRequestID:(NSNumber *)requestID;
- (void)cancelRequestWithRequestIDList:(NSArray *)requestIDList;

@end
