//
//  ZXWScaleLayout.m
//  CollectionLayoutPractice
//
//  Created by 庄晓伟 on 16/3/25.
//  Copyright © 2016年 Zhuang Xiaowei. All rights reserved.
//

#import "ZXWScaleLayout.h"

@implementation ZXWScaleLayout

- (void)prepareLayout {
    [super prepareLayout];
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *layouts = [super layoutAttributesForElementsInRect:rect];
    
    [layouts enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes * _Nonnull attrs, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat distince = fabs(attrs.center.x - CGRectGetWidth(self.collectionView.bounds) * 0.5 - self.collectionView.contentOffset.x);
        CGFloat w = (CGRectGetWidth(self.collectionView.bounds) + self.itemSize.width) * 0.5;
        CGFloat scale = 0.5f;
        if (distince >= w) {
            scale = 0.5f;
        }
        else {
            scale = scale + (1 - distince / w) * 0.5f;
            NSLog(@"%f", scale);
        }
        attrs.transform = CGAffineTransformMakeScale(scale, scale);
    }];
    return layouts;
}


- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    CGRect  rect;
    
    rect.origin = proposedContentOffset;
    rect.size = self.collectionView.frame.size;
    //获取停止时，显示的cell的frame
    NSArray *tempArray  = [super  layoutAttributesForElementsInRect:rect];
    
    CGFloat  gap = 1000;
    
    CGFloat  a = 0;
    
    for (int i = 0; i < tempArray.count; i++) {
        //判断和中心的距离，得到最小的那个
        if (gap > ABS([tempArray[i] center].x - proposedContentOffset.x - self.collectionView.frame.size.width * 0.5)) {
            
            gap =  ABS([tempArray[i] center].x - proposedContentOffset.x - self.collectionView.frame.size.width * 0.5);
            
            a = [tempArray[i] center].x - proposedContentOffset.x - self.collectionView.frame.size.width * 0.5;
            
        }
    }
    
    //把希望得到的值返回出去
    CGPoint  point  =CGPointMake(proposedContentOffset.x + a , proposedContentOffset.y);
    
    NSLog(@"%@",NSStringFromCGPoint(point));
    
    return point;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

@end
