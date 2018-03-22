//
//  ALCollectionView.m
//  UIScrollCollection
//
//  Created by 庄晓伟 on 2018/3/20.
//  Copyright © 2018年 Zhuhai Auto-Learning Co.,ltd. All rights reserved.
//

#import "ALCollectionView.h"
#import "ALBookViewModel.h"
#import "ALBookCollectionViewCell.h"

static NSString * const kCell                                           = @"ALBookCollectionViewCell";

@interface ALCollectionView() <
  UICollectionViewDataSource,
  UICollectionViewDelegate,
  UICollectionViewDelegateFlowLayout
>

@property (nonatomic, strong) UICollectionView                          *collectionView;
@property (nonatomic, copy) NSArray<ALBookViewModel *>                  *dataSource;
@property (nonatomic, assign) CGFloat                                   beginDragX;
@property (nonatomic, assign) CGFloat                                   endDragX;
@property (nonatomic, assign) NSInteger                                 curIndex;
@property (nonatomic, strong) NSArray                                   *originData;
@property (nonatomic, assign) BOOL                                      canScrollForever;

@end

@implementation ALCollectionView

//- (instancetype)initWithFrame:(CGRect)frame withLayout:(ALCollectionScrollCenterLayout *)layout {
//    if (self = [super initWithFrame:frame]) {
//        [self __setupUI];
//    }
//    return self;
//}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self __setupUI];
    }
    return self;
}

- (void)__setupUI {
    CGRect frame = self.frame;
    frame.origin.y = 20.0f;
    CGSize itemSize = frame.size;
    itemSize.width = itemSize.width / 3 + 20;
//    itemSize.width = 250.0f;
    
    ALCollectionScrollCenterLayout *flowLayout = [[ALCollectionScrollCenterLayout alloc] init];
    flowLayout.itemSize = itemSize;
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.minimumLineSpacing = 0.0f;
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:frame
                                                          collectionViewLayout:flowLayout];
    
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    [self addSubview:collectionView];
    self.collectionView = collectionView;
    
//    self.dataSource = @[
//                        [UIColor orangeColor],
//                        [UIColor purpleColor],
//                        [UIColor blueColor],
//
//                        [UIColor yellowColor],
//                        [UIColor redColor],
//                        [UIColor blackColor],
//                        [UIColor greenColor],
//                        [UIColor orangeColor],
//                        [UIColor purpleColor],
//                        [UIColor blueColor],
//
//                        [UIColor yellowColor],
//                        [UIColor redColor],
//                        [UIColor blackColor],
//                        ];
//    self.curIndex = 4;
    self.canScrollForever = NO;
//    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
//    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:4 inSection:0]
//                                atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
//                                        animated:NO];
    
    UINib *nib = [UINib nibWithNibName:@"ALBookCollectionViewCell" bundle:nil];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:kCell];
    self.collectionView.backgroundColor = BackgroundColor;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.showsHorizontalScrollIndicator = NO;
}

- (void)bindViewModel:(NSArray<ALBookViewModel *> *)datas {
    [self.collectionView setFrame:self.bounds];
    if (self.originData == datas) {
        return;
    }
    if (datas.count == 0) {
        return;
    }
    self.originData = datas;
    self.canScrollForever = datas.count >= 3;
    NSMutableArray *dataSource = [[NSMutableArray alloc] initWithCapacity:datas.count + 6];
    if (datas.count >= 3) {
        for (NSInteger i = datas.count - 3; i < datas.count; ++i) {
            [dataSource addObject:datas[i]];
        }
        [dataSource addObjectsFromArray:datas];
        for (NSInteger i = 0; i < 3; ++i) {
            [dataSource addObject:datas[i]];
        }
        self.curIndex = 4;
        self.dataSource = [dataSource copy];
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:4 inSection:0]
                                    atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                            animated:NO];
    }
    else {
        self.dataSource = [datas copy];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ALBookCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCell forIndexPath:indexPath];
    [cell bindViewModel:self.dataSource[indexPath.row]];
    
    cell.layer.contentsScale = [UIScreen mainScreen].scale;
    cell.layer.shadowOpacity = 0.25f;
    cell.layer.shadowRadius = 4.0f;
    cell.layer.shadowOffset = CGSizeMake(3,5);
    cell.layer.shadowPath = [UIBezierPath bezierPathWithRect:cell.bounds].CGPath;
    cell.layer.shouldRasterize = YES;
    cell.layer.rasterizationScale = [UIScreen mainScreen].scale;
    cell.clipsToBounds = NO;
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.curIndex) {
        [self.dataSource[indexPath.row].showPlayCommand execute:RACTuplePack(self.originData, @YES, @YES, @0)];
    }
    else {
        self.curIndex = indexPath.row;
        [collectionView scrollToItemAtIndexPath:indexPath
                               atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                       animated:YES];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (!self.canScrollForever) {
        return;
    }
    ALCollectionScrollCenterLayout *layout = (id)self.collectionView.collectionViewLayout;
    if (layout.stopScrollIndex == self.dataSource.count - 2) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (!self.canScrollForever) {
        return;
    }
    self.beginDragX = scrollView.contentOffset.x;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!self.canScrollForever) {
        return;
    }
    self.endDragX = scrollView.contentOffset.x;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self __modifyCellToCenter];
    });
}

- (void)__modifyCellToCenter {
    float dragMiniDistance = self.collectionView.bounds.size.width / 20.0f;
    if (self.beginDragX -  self.endDragX >= dragMiniDistance) {
        self.curIndex -= 1;//向右
    }else if(self.endDragX -  self.beginDragX >= dragMiniDistance){
        self.curIndex += 1;//向左
    }
    NSInteger maxIndex = [_collectionView numberOfItemsInSection:0] - 1;
    
    
    self.curIndex = self.curIndex <= 0 ? 0 : self.curIndex;
    self.curIndex = self.curIndex >= maxIndex ? maxIndex : self.curIndex;
    
    
    [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.curIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (!self.canScrollForever) {
        return;
    }
    NSInteger toIndex = -1;
    if (self.curIndex == 1) {
        toIndex = self.dataSource.count - 6 + 1;
    }
    else if (self.curIndex == self.dataSource.count - 2) {
        toIndex = 4;
    }
    if (toIndex != -1) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:toIndex inSection:0];
        [self.collectionView scrollToItemAtIndexPath:indexPath
                                    atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        self.curIndex = toIndex;
    }
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    ALCollectionScrollCenterLayout *layout = (id)self.collectionView.collectionViewLayout;
    frame.origin.y = 20.0f;
    CGSize itemSize = frame.size;
    itemSize.width = itemSize.width / 3 + 20.0f;
    itemSize.height = frame.size.height - 30.0f;
    layout.itemSize = itemSize;
}

@end
