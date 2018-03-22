//
//  CADisplayLink+ALUserInfo.m
//  AutoLearning
//
//  Created by 庄晓伟 on 16/4/25.
//  Copyright © 2016年 Zhuhai Auto-Learning Co.,Ltd. All rights reserved.
//

#import "CADisplayLink+ALUserInfo.h"
#import <objc/runtime.h>

@implementation CADisplayLink (ALUserInfo)

- (void)setAl_userInfo:(NSDictionary *)al_userInfo {
    objc_setAssociatedObject(self, "al_userInfo", al_userInfo, OBJC_ASSOCIATION_COPY);
}

- (NSDictionary *)al_userInfo {
    return objc_getAssociatedObject(self, "al_userInfo");
}

@end
