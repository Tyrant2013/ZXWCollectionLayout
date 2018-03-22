//
//  ALCollectionScrollCenterLayout.m
//  UIScrollCollection
//
//  Created by 庄晓伟 on 2018/3/19.
//  Copyright © 2018年 Zhuhai Auto-Learning Co.,ltd. All rights reserved.
//

#import "ALCollectionScrollCenterLayout.h"

@implementation ALCollectionScrollCenterLayout

//- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity {
//    //计算出 最终显示的矩形框
//    CGRect rect;
//    rect.origin.x = proposedContentOffset.x;
//    rect.origin.y = 0;
//    rect.size = self.collectionView.frame.size;
//
//    NSArray * array = [super layoutAttributesForElementsInRect:rect];
//
//    CGFloat centerX = self.collectionView.frame.size.width / 2 + proposedContentOffset.x;
//    //存放的最小间距
//    CGFloat minDelta = MAXFLOAT;
//    for (UICollectionViewLayoutAttributes * attrs in array) {
//        if (ABS(minDelta) > ABS(attrs.center.x - centerX)) {
//            minDelta = attrs.center.x - centerX;
//            self.stopScrollIndex = attrs.indexPath.item;
//        }
//    }
//    // 修改原有的偏移量
//    proposedContentOffset.x += minDelta;
//    return proposedContentOffset;
//}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *originArray = [super layoutAttributesForElementsInRect:rect];
    NSArray *array = [[NSArray alloc] initWithArray:originArray copyItems:YES];
    CGFloat centerX = self.collectionView.contentOffset.x + CGRectGetWidth(self.collectionView.frame) / 2;
    for (UICollectionViewLayoutAttributes *attrs in array) {
        CGFloat delta = ABS(attrs.center.x - centerX) / 2;
        CGFloat scale = 1 - delta / CGRectGetWidth(self.collectionView.frame);
        attrs.transform = CGAffineTransformMakeScale(1, scale);
        attrs.zIndex = 1000 - delta;
    }
    return array;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

@end
