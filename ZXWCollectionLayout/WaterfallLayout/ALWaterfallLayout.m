//
//  ALWaterfallLayout.m
//  AutoLearning
//
//  Created by 庄晓伟 on 2018/3/21.
//  Copyright © 2018年 Zhuhai Auto-Learning Co.,Ltd. All rights reserved.
//

#import "ALWaterfallLayout.h"

@interface ALWaterfallLayout()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *>           *maxY;
@property (nonatomic, strong) NSMutableArray<UICollectionViewLayoutAttributes *>    *attrsArray;

@end

@implementation ALWaterfallLayout

- (void)awakeFromNib {
    [super awakeFromNib];
    [self __initDefault];
}

- (instancetype)init {
    if (self = [super init]) {
        [self __initDefault];
    }
    return self;
}

- (void)__initDefault {
    self.maxY = [NSMutableDictionary dictionary];
    self.attrsArray = [NSMutableArray array];
    self.columnSpace = 10.0f;
    self.columnsCount = 3;
    self.rowSpace = 10.0f;
    self.sectionInset = UIEdgeInsetsMake(15.0f, 12.5f, 15.0f, 12.5f);
}

- (void)prepareLayout {
    [super prepareLayout];
    for (NSInteger index = 0; index < self.columnsCount; ++index) {
        NSString *column = [NSString stringWithFormat:@"%@", @(index)];
        self.maxY[column] = @(self.sectionInset.top);
    }
    [self.attrsArray removeAllObjects];
    NSInteger count = [self.collectionView numberOfItemsInSection:0];
    for (NSInteger index = 0; index < count; ++index) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        UICollectionViewLayoutAttributes *layoutAttr = [self layoutAttributesForItemAtIndexPath:indexPath];
        [self.attrsArray addObject:layoutAttr];
    }
}

- (CGSize)collectionViewContentSize {
    __block NSString *maxColumn = @"0";
    [self.maxY enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull maxY, BOOL * _Nonnull stop) {
        if (maxY.floatValue > self.maxY[maxColumn].floatValue) {
            maxColumn = key;
        }
    }];
    CGSize contentSize = (CGSize){CGRectGetWidth(self.collectionView.bounds), self.maxY[maxColumn].floatValue + self.sectionInset.top + self.sectionInset.bottom};
    return contentSize;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    __block NSString *minColumn = @"0";
    [self.maxY enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull maxY, BOOL * _Nonnull stop) {
        if (maxY.floatValue < self.maxY[minColumn].floatValue) {
            minColumn = key;
        }
    }];
    
    CGFloat width = (CGRectGetWidth(self.collectionView.frame) - self.sectionInset.left - self.sectionInset.right - self.columnSpace * (self.columnsCount - 1)) / self.columnsCount;
    CGFloat height = self.heightForLayout(self, width, indexPath);
    CGFloat x = self.sectionInset.left + (width + self.columnSpace) * minColumn.integerValue;
    CGFloat y = self.maxY[minColumn].floatValue + self.rowSpace;
    self.maxY[minColumn] = @(y + height);
    UICollectionViewLayoutAttributes *attrs = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    attrs.frame = (CGRect){x, y, width, height};
    return attrs;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *ret = [NSMutableArray array];
    [self.attrsArray enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (CGRectIntersectsRect(obj.frame, rect)) {
            [ret addObject:obj];
        }
    }];
    return ret;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

@end
