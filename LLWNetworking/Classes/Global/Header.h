//
//  Header.h
//  LLWNetworking
//
//  Created by Dalong on 16/7/19.
//  Copyright © 2016年 Dalong. All rights reserved.
//

#ifndef Header_h
#define Header_h

#define ALERT_MSG(msg) static UIAlertView *alert; alert = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];\
[alert show]\

#define NETWORKERROR @"网络连接错误"

#endif /* Header_h */
