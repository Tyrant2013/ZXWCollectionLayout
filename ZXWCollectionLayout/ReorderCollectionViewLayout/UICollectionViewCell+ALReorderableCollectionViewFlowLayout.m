//
//  UICollectionViewCell+ALReorderableCollectionViewFlowLayout.m
//  AutoLearning
//
//  Created by 庄晓伟 on 16/4/25.
//  Copyright © 2016年 Zhuhai Auto-Learning Co.,Ltd. All rights reserved.
//

#import "UICollectionViewCell+ALReorderableCollectionViewFlowLayout.h"

@implementation UICollectionViewCell (ALReorderableCollectionViewFlowLayout)

- (UIView *)al_snapshotView {
    return [self snapshotViewAfterScreenUpdates:YES];
}

@end
