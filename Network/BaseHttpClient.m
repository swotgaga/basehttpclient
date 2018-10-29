
//
//  BaseHttpClient.m
//  HandServiceBox
//
//  Created by JellySix on 2017/3/21.
//  Copyright © 2017年 JellySix. All rights reserved.
//

#import "BaseHttpClient.h"
#import <UIKit/UIKit.h>
#import "ToolClass.h"

static BaseHttpClient *sharedClient = nil;
//一开始没有对象 指向nil

@interface BaseHttpClient()



@end

@implementation BaseHttpClient

#pragma mark -- 自定义构造方法
- (instancetype)initWithBaseURL:(NSString *)baseURL{
    //需要传递一个baseURL 为了以后接口功能的拓展
    
    if (self = [super init]) {
        
        _baseURL = baseURL;
        
        //检验证书
        NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"https" ofType:@"cer"];
        NSData *certData = [NSData dataWithContentsOfFile:cerPath];
        //AFSSLPinningModeCertificate 使用证书验证模式
        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
        //allowInvalidCertificates 是否允许无效证书（也就是自建的证书），默认为NO
        //如果是需要验证自建证书，需要设置为YES
        securityPolicy.allowInvalidCertificates = YES;
        securityPolicy.validatesDomainName = NO;
        NSSet *set = [[NSSet alloc] initWithObjects:certData, nil];
        securityPolicy.pinnedCertificates = set;
        
        
        _manager = [AFHTTPSessionManager manager];
        
        _manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        
        _manager.requestSerializer = [AFJSONRequestSerializer serializer];
        _manager.responseSerializer = [AFJSONResponseSerializer serializer];
        [_manager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
        _manager.requestSerializer.timeoutInterval = 10.0;
        [_manager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
        _manager.responseSerializer.acceptableContentTypes = [[NSSet alloc]initWithObjects:@"text/html",@"application/json",@"text/plain",@"text/json",@"text/javascript", nil];
        
        
        [_manager setSecurityPolicy:securityPolicy];
        
        
        [_manager.requestSerializer setValue:[ToolClass arcCheckNumberString] forHTTPHeaderField:@"Sign"];
        
        NSString *str = [[NSUserDefaults standardUserDefaults] objectForKey:@"Token"];
        [_manager.requestSerializer setValue:str forHTTPHeaderField:@"UserToken"];
        
        
    }
    
    return self;
    
}
#pragma mark -- 单例方法
+ (BaseHttpClient *)sharedClient{
    
    static dispatch_once_t oneceToken;
    
    dispatch_once(&oneceToken, ^{
        //代码片段 只被执行一次
        
        sharedClient = [[self alloc]initWithBaseURL:@""];
        
        
    });
    [sharedClient.manager.requestSerializer setValue:[ToolClass arcCheckNumberString] forHTTPHeaderField:@"Sign"];
    NSString *str = [[NSUserDefaults standardUserDefaults] objectForKey:@"Token"];
    [sharedClient.manager.requestSerializer setValue:str forHTTPHeaderField:@"UserToken"];
    
    
    return sharedClient;
    
}
#pragma mark -- 公共的请求方法 head中含有三个参数的
+ (NSURL *)httpType:(BASE_HTTP_TYPEWITHHEAD)type andURL:(NSString *)url andParam:(id)param andshopid:(NSString *)shopid andSuccessBlock:(httpSuccessBlock)sucBlock andFailBlock:(httpFailBlock)failBlock{
    //1.检查当前的网络状态 如果没有网络 直接返回错误信息 如果有网络 判断type的值 分别调用相应的方法
    
    //2.if else 分别调用封装好的方法
    
    if ([ISNull isNilOfSender:url]) {
        //url为空
        
#if 0
        //测试代码 如果上线 注掉
        
        NSError *error = [[NSError alloc]initWithDomain:@"url为空！" code:9999 userInfo:nil];
        failBlock(nil, error);
#endif
        
        NSLog(@"请求的地址为空");
        //注意  如果希望用户看到url为空的提示 就回调block 如果不希望就不写
        
        return nil;
        
        
    }
    
    if([self netIsReachability]){
        //有网络情况 判断请求类型 调用不同的方法

        if(type == GETWITHHEAD){
            
            return [self requestGETWithURL:url andshopid:shopid andParam:param andSuccessBlock:sucBlock andFailBlock:failBlock];
            
        }else if (type == POSTWITHHEAD){
            
            return [self requestPOSTWithURL:url andshopid:shopid andParam:param andSuccessBlock:sucBlock andFailBlock:failBlock];
            
        }else if(type == PUTWITHHEAD){
            
            return [self requestPUTWithURL:url andshopid:shopid andParam:param andSuccessBlock:sucBlock andFailBlock:failBlock];
        }else{
            
            return [self requestDELETEWithURL:url andshopid:shopid andParam:param andSuccessBlock:sucBlock andFailBlock:failBlock];
        }
        
        
        
    }else{
        
        UIAlertController *alertController=[UIAlertController alertControllerWithTitle:@"提示" message:@"没有网络，请检查网络连接"preferredStyle:UIAlertControllerStyleAlert];
        //创建按钮
        UIAlertAction *OKAction = [UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            
            
        }];
        // 创建按钮
        // 注意取消按钮只能添加一个
        UIAlertAction *canceAction = [UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            // 点击按钮后的方法直接在这里面写
        }];
        
        [alertController addAction:canceAction];
        [alertController addAction:OKAction];
        
        // 将UIAlertController模态出来 相当于UIAlertView show 的方法
        
        UITabBarController *tab = (UITabBarController *)[UIApplication sharedApplication].keyWindow.rootViewController
        ;
        
        UINavigationController *nav = (UINavigationController *)tab.selectedViewController;
        
        //        NavTabController *ntc = self.parentViewController;
        UIViewController *vc = [nav.viewControllers lastObject];
        
        [vc presentViewController:alertController animated:YES completion:nil];
        
        
        NSLog(@"当前没有网络");
        return nil;
    }
    
    
    return nil;

}
#pragma mark -- 公共的请求方法
+ (NSURL *)httpType:(BASE_HTTP_TYPE)type andURL:(NSString *)url andParam:(id)param andSuccessBlock:(httpSuccessBlock)sucBlock andFailBlock:(httpFailBlock)failBlock{
    //1.检查当前的网络状态 如果没有网络 直接返回错误信息 如果有网络 判断type的值 分别调用相应的方法
    
    //2.if else 分别调用封装好的方法
    
    if ([ISNull isNilOfSender:url]) {
        //url为空
        
#if 0
        //测试代码 如果上线 注掉
        
        NSError *error = [[NSError alloc]initWithDomain:@"url为空！" code:9999 userInfo:nil];
        failBlock(nil, error);
#endif
        
        NSLog(@"请求的地址为空");
        //注意  如果希望用户看到url为空的提示 就回调block 如果不希望就不写
        
        return nil;
        
        
    }
    
    if([self netIsReachability]){
        //有网络情况 判断请求类型 调用不同的方法
        
        if(type == GET){
            
            return   [self requestGETWithURL:url andParam:param andSuccessBlock:sucBlock andFailBlock:failBlock];
            
        }else if (type == POST){
            
            return [self requestPOSTWithURL:url andParam:param andSuccessBlock:sucBlock andFailBlock:failBlock];
            
        }else if(type == PUT){
            
            return [self requestPUTWithURL:url andParam:param andSuccessBlock:sucBlock andFailBlock:failBlock];
        }else{
            
            return [self requestDELETEWithURL:url andParam:param andSuccessBlock:sucBlock andFailBlock:failBlock];
        }
        
        
        
    }else{
        
        
        
        UIAlertController *alertController=[UIAlertController alertControllerWithTitle:@"提示" message:@"没有网络，请检查网络连接"preferredStyle:UIAlertControllerStyleAlert];
        //创建按钮
        UIAlertAction *OKAction = [UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            
            
        }];
        // 创建按钮
        // 注意取消按钮只能添加一个
        UIAlertAction *canceAction = [UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            // 点击按钮后的方法直接在这里面写
        }];
        [alertController addAction:OKAction];
        [alertController addAction:canceAction];
        // 将UIAlertController模态出来 相当于UIAlertView show 的方法
        
        UITabBarController *tab = (UITabBarController *)[UIApplication sharedApplication].keyWindow.rootViewController
        ;
        
        UINavigationController *nav = (UINavigationController *)tab.selectedViewController;
        
        //        NavTabController *ntc = self.parentViewController;
        UIViewController *vc = [nav.viewControllers lastObject];
        
        [vc presentViewController:alertController animated:YES completion:nil];
        
        
        NSLog(@"当前没有网络");
        return nil;
    }
    
    
    return nil;
}
-(void)createNewmanager:(NSString *)shopid{
    _managerWithhead = [AFHTTPSessionManager manager];
    _managerWithhead.securityPolicy=[AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    _managerWithhead.requestSerializer=[AFJSONRequestSerializer serializer];
    _managerWithhead.responseSerializer = [AFJSONResponseSerializer serializer];
    _managerWithhead.responseSerializer.acceptableContentTypes = [[NSSet alloc]initWithObjects:@"text/html",@"application/json",@"text/plain",@"text/json",@"charset=utf-8",@"text/javascript", nil];
    [_managerWithhead.requestSerializer setValue:[NSString stringWithFormat:@"%@",shopid] forHTTPHeaderField:@"shopid"];
    [_managerWithhead.requestSerializer setValue:[ToolClass arcCheckNumberString] forHTTPHeaderField:@"Sign"];
    
    NSString *str = [[NSUserDefaults standardUserDefaults] objectForKey:@"Token"];
    [_managerWithhead.requestSerializer setValue:str forHTTPHeaderField:@"UserToken"];

}
#pragma mark -- GET 方法的封装(head里带有shopid)

+ (NSURL *)requestGETWithURL:(NSString *)url andshopid:(NSString *)shopid andParam:(NSDictionary *)param andSuccessBlock:(httpSuccessBlock)sucBlock andFailBlock:(httpFailBlock)failBlock{
    
    //先判断url是否为空 放到共有的方法中去判断
    
    //如果不为空 请求数据
    //数据解析回调
    BaseHttpClient *client = [[BaseHttpClient alloc]init];
    
    //1.创建_managerWithhead
    [client createNewmanager:shopid];
   
    //2.拼接请求地址 服务器的地址+资源的文件路径
    client.baseURL=@"";
    NSString *signUrl = [NSString stringWithFormat:@"%@%@",client.baseURL, url];
    
    //3.请求的合法化
    //    signUrl = [signUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    //最新的替换方法
    signUrl = [signUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    
    NSURL *returnURL = [NSURL URLWithString:signUrl];
    
    
    //4.进行网络请求
    
    [client.managerWithhead GET:signUrl parameters:param progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
//        NSString *str = [[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
        
        NSString *str = [ToolClass convertToJsonData:responseObject];
        NSLog(@"%@",str);
        
        
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
            if (responseObject == nil) {
                
                //数据请求失败
                NSError *error = [[NSError alloc]initWithDomain:@"网络请求数据为空!" code:9999 userInfo:nil];
                
                failBlock(returnURL, error);
                
                
            }else{
                
                
                //数据解析 可能是数组 也可能是字典
                
                
                //(1)JSON解析
                
//                id obejct = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
                
                
                //(2)由于成功的block回调参数本身就是id 因此具体是数组还是字典 可以由UI自己去判断
                
                sucBlock(returnURL, responseObject);
                
                
            }
            
        });
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            failBlock(returnURL, error);
        });
        
        
    }];
    
    
    return returnURL;
    
}



#pragma mark -- GET 方法的封装

+ (NSURL *)requestGETWithURL:(NSString *)url andParam:(NSDictionary *)param andSuccessBlock:(httpSuccessBlock)sucBlock andFailBlock:(httpFailBlock)failBlock{
    
    //先判断url是否为空 放到共有的方法中去判断
    
    //如果不为空 请求数据
    //数据解析回调
    
    //1.创建单例
    BaseHttpClient *client = [BaseHttpClient sharedClient];
    
    [[UIApplication sharedApplication].keyWindow addSubview:client.aView];
    
    //2.拼接请求地址 服务器的地址+资源的文件路径
    
    NSString *signUrl = [NSString stringWithFormat:@"%@%@",client.baseURL, url];
    
    //3.请求的合法化
    //    signUrl = [signUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    //最新的替换方法
    signUrl = [signUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    
    NSURL *returnURL = [NSURL URLWithString:signUrl];
    
    
    //4.进行网络请求
    
    [client.manager GET:signUrl parameters:param progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [client.aView removeFromSuperview];
        
//        NSString *str = [[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
        
        NSString *str = [ToolClass convertToJsonData:responseObject];
        NSLog(@"%@",str);
        
        
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
            if (responseObject == nil) {
                
                //数据请求失败
                NSError *error = [[NSError alloc]initWithDomain:@"网络请求数据为空!" code:9999 userInfo:nil];
                
                failBlock(returnURL, error);
                
                
            }else{
                
                
                //数据解析 可能是数组 也可能是字典
                
                
                //(1)JSON解析
                
//                id obejct1 = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
                
                id obejct = responseObject;
                
                
                //(2)由于成功的block回调参数本身就是id 因此具体是数组还是字典 可以由UI自己去判断
                
                sucBlock(returnURL, obejct);
                
                
            }
            
        });
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [client.aView removeFromSuperview];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            failBlock(returnURL, error);
        });

        
    }];
    
    
    
    
    return returnURL;
    
}
#pragma mark -- POST 方法封装(head里带有shopid)

+ (NSURL *)requestPOSTWithURL:(NSString *)url andshopid:(NSString *)shopid andParam:(id)param andSuccessBlock:(httpSuccessBlock)sucBlock andFailBlock:(httpFailBlock)failBlock{
    
    
    BaseHttpClient *client = [[BaseHttpClient alloc]init];
    
    //1.创建_managerWithhead
    [client createNewmanager:shopid];
    client.baseURL=@"";
    NSString *signUrl = [NSString stringWithFormat:@"%@%@",client.baseURL, url];
    
    
    signUrl = [signUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet  URLQueryAllowedCharacterSet]];
    
    NSURL *returnURL = [NSURL URLWithString:signUrl];
    
    [client.managerWithhead POST:signUrl parameters:param progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSString *str = [ToolClass convertToJsonData:responseObject];
        NSLog(@"%@",str);
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
//            NSString *dataStr = [[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
//            NSLog(@"***************data:%@",dataStr);
//            
            if (responseObject == nil) {
                
                NSError *error = [NSError errorWithDomain:@"网络请求数据为空!" code:9999 userInfo:nil];
                failBlock(returnURL, error);
            }else{
                
//                id object = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
                
                sucBlock(returnURL, responseObject);
                
            }
        });
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            failBlock(returnURL, error);
        });
        
    }];
    
    
    
    return returnURL;
    
    
}

#pragma mark -- POST 方法封装

+ (NSURL *)requestPOSTWithURL:(NSString *)url andParam:(id)param andSuccessBlock:(httpSuccessBlock)sucBlock andFailBlock:(httpFailBlock)failBlock{
    
    
    BaseHttpClient *client = [BaseHttpClient sharedClient];
    
    [[UIApplication sharedApplication].keyWindow addSubview:client.aView];
    
    NSString *signUrl = [NSString stringWithFormat:@"%@%@",client.baseURL, url];
    
    
    signUrl = [signUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet  URLQueryAllowedCharacterSet]];
    
    NSURL *returnURL = [NSURL URLWithString:signUrl];
    
    [client.manager POST:signUrl parameters:param progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [client.aView removeFromSuperview];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
//            NSString *dataStr = [[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
            
            NSString *dataStr = responseObject;
            NSLog(@"***************data:%@",dataStr);
            
            if (responseObject == nil) {
                
                NSError *error = [NSError errorWithDomain:@"网络请求数据为空!" code:9999 userInfo:nil];
                failBlock(returnURL, error);
            }else{
                
//                id object = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
                
                sucBlock(returnURL, responseObject);
                
            }
        });
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [client.aView removeFromSuperview];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            failBlock(returnURL, error);
        });
        
    }];
    
    
    
    return returnURL;
    
    
}
#pragma mark -- PUT 方法的封装(head里带有shopid)

+ (NSURL *)requestPUTWithURL:(NSString *)url andshopid:(NSString *)shopid andParam:(NSDictionary *)param andSuccessBlock:(httpSuccessBlock)sucBlock andFailBlock:(httpFailBlock)failBlock{
    
    
    BaseHttpClient *client = [[BaseHttpClient alloc]init];
    
    //1.创建_managerWithhead
    [client createNewmanager:shopid];
    client.baseURL=@"";
    NSString *signUrl = [NSString stringWithFormat:@"%@%@",client.baseURL, url];
    NSURL *returnURL = [NSURL URLWithString:signUrl];
    
    [client.managerWithhead PUT:signUrl parameters:param success:^(NSURLSessionDataTask *task, id responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (responseObject == nil) {
                
                NSError *error = [[NSError alloc]initWithDomain:@"网络请求数据为空!" code:9999 userInfo:nil];
                
                failBlock(returnURL, error);
            }else{
                
//                id object = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
                sucBlock(returnURL, responseObject);
                
            }
        });
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            failBlock(returnURL, error);
        });
        
    }];
    
    return returnURL;
    
}

#pragma mark -- PUT 方法的封装

+ (NSURL *)requestPUTWithURL:(NSString *)url andParam:(NSDictionary *)param andSuccessBlock:(httpSuccessBlock)sucBlock andFailBlock:(httpFailBlock)failBlock{
    
    
    BaseHttpClient *client = [BaseHttpClient sharedClient];
    
    NSString *signUrl = [NSString stringWithFormat:@"%@%@",client.baseURL, url];
    NSURL *returnURL = [NSURL URLWithString:signUrl];
    
    [client.manager PUT:signUrl parameters:param success:^(NSURLSessionDataTask *task, id responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (responseObject == nil) {
                
                NSError *error = [[NSError alloc]initWithDomain:@"网络请求数据为空!" code:9999 userInfo:nil];
                
                failBlock(returnURL, error);
            }else{
                
//                id object = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
                sucBlock(returnURL, responseObject);
                
            }
        });
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            failBlock(returnURL, error);
        });
        
    }];
    
    return returnURL;
    
}
#pragma mark -- DELETE 方法的封装(head里带有shopid)

+ (NSURL *)requestDELETEWithURL:(NSString *)url andshopid:(NSString *)shopid andParam:(NSDictionary *)param andSuccessBlock:(httpSuccessBlock)sucBlock andFailBlock:(httpFailBlock)failBlock{
    
    
    BaseHttpClient *client = [[BaseHttpClient alloc]init];
    
    //1.创建_managerWithhead
    [client createNewmanager:shopid];
    client.baseURL=@"";
    NSString *signUrl = [NSString stringWithFormat:@"%@%@",client.baseURL, url];
    NSURL *returnURL = [NSURL URLWithString:signUrl];
    
    [client.managerWithhead DELETE:signUrl parameters:param success:^(NSURLSessionDataTask *task, id responseObject) {
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (responseObject == nil) {
                
                NSError *error = [[NSError alloc]initWithDomain:@"网络请求数据为空!" code:9999 userInfo:nil];
                
                failBlock(returnURL, error);
            }else{
                
//                id object = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
                sucBlock(returnURL, responseObject);
                
            }
            
        });
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
            failBlock(returnURL, error);
            
        });
        
    }];
    
    return returnURL;
    
}

#pragma mark -- DELETE 方法的封装

+ (NSURL *)requestDELETEWithURL:(NSString *)url andParam:(NSDictionary *)param andSuccessBlock:(httpSuccessBlock)sucBlock andFailBlock:(httpFailBlock)failBlock{
    
    
    BaseHttpClient *client = [BaseHttpClient sharedClient];
    
    NSString *signUrl = [NSString stringWithFormat:@"%@%@",client.baseURL, url];
    NSURL *returnURL = [NSURL URLWithString:signUrl];
    
    [client.manager DELETE:signUrl parameters:param success:^(NSURLSessionDataTask *task, id responseObject) {
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (responseObject == nil) {
                
                NSError *error = [[NSError alloc]initWithDomain:@"网络请求数据为空!" code:9999 userInfo:nil];
                
                failBlock(returnURL, error);
            }else{
                
//                id object = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
                sucBlock(returnURL, responseObject);
                
            }
            
        });
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
            failBlock(returnURL, error);
            
        });
        
    }];
    
    return returnURL;
    
}





#pragma mark -- 检查当前网络是否可用
//Reachability

+ (BOOL)netIsReachability{
    
    // yes 有网络 no无网络
    
    return [[Reachability reachabilityForInternetConnection] isReachable];
#if 0
    Reachability *reach = [Reachability reachabilityForInternetConnection];
    return [reach isReachable];
#endif
}

#pragma mark -- 表单上传图片
//普通表单上传图片
+ (NSURL *)postImage:(NSArray *)imageArr andURL:(NSString *)url andParam:(id)param andProgress:(httpProgressBlock)progressBlock andSuccessBlock:(httpSuccessBlock)sucBlock andFailBlock:(httpFailBlock)failBlock {
    
    BaseHttpClient *client = [BaseHttpClient sharedClient];
    
    NSString *signUrl = [NSString stringWithFormat:@"%@%@",client.baseURL, url];
    NSURL *returnURL = [NSURL URLWithString:signUrl];
    
    [client.manager POST:signUrl parameters:param constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        for (int i = 0; i < imageArr.count; i++) {
            NSData *data = nil;
            if (UIImagePNGRepresentation(imageArr[i])) {
                data = UIImagePNGRepresentation(imageArr[i]);
            }else {
                data = UIImageJPEGRepresentation(imageArr[i], 1.0);
            }
            
            NSString *fileName = [NSString stringWithFormat:@"tx%d.png",i];
            [formData appendPartWithFileData:data name:@"pic" fileName:fileName mimeType:@"image/png"];
        }
        
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
            //progressBlock(returnURL, uploadProgress);
            AppDelegate *appdelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
            [appdelegate showLoading:@"图片上传中"];
            
        });
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        AppDelegate *appdelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [appdelegate hideLoading];
        
//        NSString *dataStr = [[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"***************data:%@",responseObject);
        
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
//            NSString *dataStr = [[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
//            NSLog(@"***************data:%@",dataStr);
            
            if (responseObject == nil) {
                
                NSError *error = [NSError errorWithDomain:@"网络请求数据为空!" code:9999 userInfo:nil];
                failBlock(returnURL, error);
            }else{
                
//                id object = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
                
                sucBlock(returnURL, responseObject);
                
            }
        });                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        AppDelegate *appdelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [appdelegate hideLoading];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
            failBlock(returnURL, error);
            
        });
        
    }];
    
    
    return  returnURL;
    
    
}


#pragma mark -- 取消请求

+ (void)cancelHTTPRequestOperations{
    
    BaseHttpClient *client = [BaseHttpClient sharedClient];
    
    [client.manager.operationQueue cancelAllOperations];
    //取消manager队列中的中的所有任务
    
    
    
}

#pragma mark - 加载动画
- (UIView *)aView {
    
    if (!_aView) {
        
        _aView = [[UIView alloc] initWithFrame:[UIApplication sharedApplication].keyWindow.frame];
        _aView.backgroundColor = [UIColor whiteColor];
        
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 150)];
        imageView.center = CGPointMake([UIApplication sharedApplication].keyWindow.frame.size.width/2, 200);
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_aView addSubview:imageView];
        
        // 1.将序列图加入数组
        NSMutableArray *imagesArray = [[NSMutableArray alloc] init];
        for(int i=1;i < 4;i++)
        {
            UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"jiazaizhong%d.png",i]];
            [imagesArray addObject:image];
        }
        
        // 设置序列图数组
        imageView.animationImages = imagesArray;
        // 设置播放周期时间
        imageView.animationDuration = 2;
        // 设置播放次数
        imageView.animationRepeatCount = 0;
        // 播放动画
        [imageView startAnimating];
        
    }
    
    return _aView;
    
}


@end
