//
//  ALReorderCollectionViewLayout.h
//  AutoLearning
//
//  Created by 庄晓伟 on 16/4/25.
//  Copyright © 2016年 Zhuhai Auto-Learning Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ALReorderCollectionViewLayoutDataSource <UICollectionViewDataSource>

@optional

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath;
- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didMoveToIndexPath:(NSIndexPath *)toIndexPath;

- (void)collectionView:(UICollectionView *)collectionView willBeginMoveItemAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath;

@end

@protocol ALReorderCollectionViewLayoutDelegateFlowLayout <UICollectionViewDelegateFlowLayout>

@optional

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout willBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout willEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface ALReorderCollectionViewLayout : UICollectionViewFlowLayout <UIGestureRecognizerDelegate>

@property (nonatomic, assign) CGFloat                                   scrollingSpeed;
@property (nonatomic, assign) UIEdgeInsets                              scrollingTriggerEdgeInsets;
@property (nonatomic, strong) UILongPressGestureRecognizer              *longPressGestureRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer                    *panGestureRecognizer;

@end
