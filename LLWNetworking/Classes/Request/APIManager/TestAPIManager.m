//
//  TestAPIManager.m
//  LLWNetworking
//
//  Created by Dalong on 16/7/7.
//  Copyright © 2016年 Dalong. All rights reserved.
//

#import "TestAPIManager.h"

@interface TestAPIManager () <APIManagerDataReformer>

@end

@implementation TestAPIManager

#pragma mark - life cycle
- (instancetype)init {
    self = [super init];
    if (self) {
        self.reformer = self;
        self.pageNum = 1;
    }
    return self;
}

#pragma mark - APIManager
- (NSString *)requestUrl {
//    return kTestUrl;
    return @"http://api.mishi.cn/index/goods/home/?p-pv=1.0&p-rtType=json_orig_result&p-apiv=1.0&city=%E6%B7%B1%E5%9C%B3%E5%B8%82&cityCode=0755&currentPage=1&lat=22.58055406301817&lng=113.8994404578979&p-apiv=1.0&pageSize=10&sortType=1";
}

- (APIRequestType)requestType {
    return APIRequestTypeGet;
}

- (NSDictionary *)requestWithParams:(NSDictionary *)params {
    NSDictionary *apiParams = @{
                                @"PageIndex":[NSString stringWithFormat:@"%zi",self.pageNum],
                                @"PageSize":@"10",
//                                @"id":params[@"id"]
                                };
    return apiParams;
}

- (BOOL)shouldCache {
    return YES;
}

#pragma mark - APIManagerDataReformer
- (id)reformerWithData:(NSDictionary *)data {
    NSLog(@"返回数据转换");
    return nil;
}

@end
