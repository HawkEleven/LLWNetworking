//
//  ViewController.m
//  LLWNetworking
//
//  Created by Dalong on 16/7/7.
//  Copyright © 2016年 Dalong. All rights reserved.
//

#import "ViewController.h"
#import "TestAPIManager.h"

@interface ViewController () <BaseAPIManagerCallBackDelegate>

@property (nonatomic, strong) TestAPIManager *testAPIManager;

@end

@implementation ViewController

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    [self.testAPIManager startRequest];
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    //    [self.testAPIManager cancelAllRequests];
    
    // 模拟上拉加载
    self.testAPIManager.pageNum ++;
    [self.testAPIManager startRequest];
}

#pragma mark - APIManagerDelegate
- (void)managerCallAPIDidSuccess:(BaseAPIManager *)manager {
    if (manager == self.testAPIManager) {
        NSLog(@"model:%@",manager.fetchedData);
    }
}

- (void)managerCallAPIDidFailed:(BaseAPIManager *)manager {
    
}

#pragma mark - =====getters and setters=====
#pragma mark - getter
- (TestAPIManager *)testAPIManager {
    if (!_testAPIManager) {
        _testAPIManager = [[TestAPIManager alloc] init];
        
        _testAPIManager.delegate = self;
    }
    return _testAPIManager;
}

@end
