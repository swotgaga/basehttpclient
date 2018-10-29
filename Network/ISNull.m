//
//  ISNull.m
//  HandServiceBox
//
//  Created by JellySix on 2017/3/21.
//  Copyright © 2017年 JellySix. All rights reserved.
//

#import "ISNull.h"

@implementation ISNull

+ (BOOL)isNilOfSender:(NSObject *)sender {
    
    if (!sender) {
        return YES;
    }
    
    if ([sender isKindOfClass:[NSArray class]]) {
        NSArray *array = (NSArray *)sender;
        if (array.count) {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    
    if ([sender isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dic = (NSDictionary *)sender;
        if ([dic allKeys].count) {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    
    if ([sender isKindOfClass:[NSString class]]) {
        NSString *str = (NSString *)sender;
        if (str != NULL && [str stringByReplacingOccurrencesOfString:@" " withString:@""].length > 0) {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    
    return YES;
}


@end
