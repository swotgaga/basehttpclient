//
//  BaseHttpClient.h
//  HandServiceBox
//
//  Created by JellySix on 2017/3/21.
//  Copyright © 2017年 JellySix. All rights reserved.
//


/*
 block进行回调
 枚举 区分不同类型的请求
 GCD 多线程处理 （AF中的方法也封装有）
 reachability 网络状态监测
 JSON解析 （XML解析）
 */

#import <Foundation/Foundation.h>
#import "AFNetworking.h"
#import "Reachability.h"
#import "ISNull.h"

// GET POST PUT DELETE 枚举值表示不同的请求类型
typedef enum {
    
    GET = 1,
    POST,
    PUT,
    DELETE,
    
}BASE_HTTP_TYPE;

typedef enum {
    
    GETWITHHEAD = 1,
    POSTWITHHEAD,
    PUTWITHHEAD,
    DELETEWITHHEAD,
    
}BASE_HTTP_TYPEWITHHEAD;

//typedef block类型 方便表示一个block
typedef void(^httpSuccessBlock)(NSURL *URL, id data);
//成功时回调用的block 参数：请求的地址  回调的数据 id可以使字典也可以是数组
typedef void(^httpFailBlock)(NSURL *URL, NSError *error);
//失败时回调用的block 参数：请求的地址  失败的错误信息
typedef void(^httpProgressBlock)(NSURL *URL,NSProgress *progress);
//上传时回调用的block 参数：请求的地址  上传进度


@interface BaseHttpClient : NSObject

@property (nonatomic, strong) AFHTTPSessionManager *manager;

@property (nonatomic, strong) AFHTTPSessionManager *managerWithhead;
//AF 中的sessionManager 用于发起请求

@property (nonatomic, copy)   NSString *baseURL;
//服务器地址 请求的“头”

@property (nonatomic, strong) UIView *aView;//加载动画

//单例方法
+ (BaseHttpClient *)sharedClient;

//公共的请求方法
+ (NSURL *)httpType:(BASE_HTTP_TYPE)type andURL:(NSString *)url andParam:(id)param andSuccessBlock:(httpSuccessBlock)sucBlock andFailBlock:(httpFailBlock)failBlock;
//公共的请求方法-->head中含有三个参数的
+ (NSURL *)httpType:(BASE_HTTP_TYPEWITHHEAD)type andURL:(NSString *)url andParam:(NSDictionary *)param andshopid:(NSString *)shopid andSuccessBlock:(httpSuccessBlock)sucBlock andFailBlock:(httpFailBlock)failBlock;
//type：请求的方式
//url：请求的地址
//param：请求的参数
//block：成功或者失败回调的block
//返回值：目的是调用方式 可以通过返回值 知道是哪一个接口

//普通上传照片
+ (NSURL *)postImage:(NSArray *)imageArr andURL:(NSString *)url andParam:(id)param andProgress:(httpProgressBlock)progressBlock andSuccessBlock:(httpSuccessBlock)sucBlock andFailBlock:(httpFailBlock)failBlock;

//取消请求的方法
+ (void)cancelHTTPRequestOperations;

@end
