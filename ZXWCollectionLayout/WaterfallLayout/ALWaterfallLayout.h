//
//  ALWaterfallLayout.h
//  AutoLearning
//
//  Created by 庄晓伟 on 2018/3/21.
//  Copyright © 2018年 Zhuhai Auto-Learning Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ALWaterfallLayout;

@protocol ALWaterfallLayoutDelegate

- (CGFloat)waterfallLayout:(ALWaterfallLayout *)layout heightForWidth:(CGFloat)width atIndexPath:(NSIndexPath *)indexPath;

@end

@interface ALWaterfallLayout : UICollectionViewLayout

@property (nonatomic, assign) CGFloat                                   columnSpace;
@property (nonatomic, assign) CGFloat                                   rowSpace;
@property (nonatomic, assign) NSInteger                                 columnsCount;
@property (nonatomic, assign) UIEdgeInsets                              sectionInset;
@property (nonatomic, copy) CGFloat(^heightForLayout)(ALWaterfallLayout *layout, CGFloat width, NSIndexPath *indexPath);

@end
