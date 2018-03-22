//
//  ALReorderCollectionViewLayout.m
//  AutoLearning
//
//  Created by 庄晓伟 on 16/4/25.
//  Copyright © 2016年 Zhuhai Auto-Learning Co.,Ltd. All rights reserved.
//

#import "ALReorderCollectionViewLayout.h"
#import <objc/runtime.h>
#import "CADisplayLink+ALUserInfo.h"
#import "UICollectionViewCell+ALReorderableCollectionViewFlowLayout.h"

CG_INLINE CGPoint
AL_CGPointAdd(CGPoint point1, CGPoint point2) {
    return CGPointMake(point1.x + point2.x, point1.y + point2.y);
}

typedef NS_ENUM(NSInteger, ALScrollingDirection) {
    ALScrollingDirectionUnknow,
    ALScrollingDirectionUp,
    ALScrollingDirectionDown,
    ALScrollingDirectionLeft,
    ALScrollingDirectionRight
};

static NSString * const kALScrollingDirectionKey = @"ALScrollingDirection";
static NSString * const kALCollectionViewKeyPath = @"collectionView";

@interface ALReorderCollectionViewLayout()

@property (nonatomic, strong) NSIndexPath                                       *selectedItemIndexPath;
@property (nonatomic, strong) UIView                                            *currentView;
@property (nonatomic, assign) CGPoint                                           currentViewCenter;
@property (nonatomic, assign) CGPoint                                           panTranslationInCollectionView;
@property (nonatomic, strong) CADisplayLink                                     *displayLink;

@property (nonatomic, weak) id<ALReorderCollectionViewLayoutDataSource>         dataSource;
@property (nonatomic, weak) id<ALReorderCollectionViewLayoutDelegateFlowLayout> delegate;

@end

@implementation ALReorderCollectionViewLayout

- (void)setDefaults {
    _scrollingSpeed = 300.0f;
    _scrollingTriggerEdgeInsets = UIEdgeInsetsMake(50.0f, 50.0f, 50.0f, 50.0f);
}

- (void)setupCollectionView {
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(hanleLongPressGesture:)];
    _longPressGestureRecognizer.delegate = self;
    
    for (UIGestureRecognizer *gestureRecognizer in self.collectionView.gestureRecognizers) {
        if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
            [gestureRecognizer requireGestureRecognizerToFail:_longPressGestureRecognizer];
        }
    }
    
    [self.collectionView addGestureRecognizer:_longPressGestureRecognizer];
    
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    _panGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer:_panGestureRecognizer];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)tearDownCollectionView {
    if (_longPressGestureRecognizer) {
        UIView *view = _longPressGestureRecognizer.view;
        if (view) {
            [view removeGestureRecognizer:_longPressGestureRecognizer];
        }
        _longPressGestureRecognizer.delegate = nil;
        _longPressGestureRecognizer = nil;
    }
    
    if (_panGestureRecognizer) {
        UIView *view = _panGestureRecognizer.view;
        if (view) {
            [view removeGestureRecognizer:_panGestureRecognizer];
        }
        _panGestureRecognizer.delegate = nil;
        _panGestureRecognizer = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)invalidateLayoutIfNecessary {
    NSIndexPath *newIndexPath = [self.collectionView indexPathForItemAtPoint:self.currentView.center];
    NSIndexPath *previousIndexPath = self.selectedItemIndexPath;
    if ((newIndexPath == nil) || ([newIndexPath isEqual:previousIndexPath])) {
        return;
    }
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:canMoveToIndexPath:)]) {
        BOOL canMove = [self.dataSource collectionView:self.collectionView itemAtIndexPath:previousIndexPath canMoveToIndexPath:newIndexPath];
        if (!canMove) {
            return;
        }
    }
    self.selectedItemIndexPath = newIndexPath;
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:willMoveToIndexPath:)]) {
        [self.dataSource collectionView:self.collectionView itemAtIndexPath:previousIndexPath willMoveToIndexPath:newIndexPath];
    }
    
    __weak typeof(self) weakSelf = self;
    [self.collectionView performBatchUpdates:^{
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf.collectionView deleteItemsAtIndexPaths:@[previousIndexPath]];
            [strongSelf.collectionView insertItemsAtIndexPaths:@[newIndexPath]];
        }
    } completion:^(BOOL finished) {
        __strong typeof(self) strongSelf = weakSelf;
        if ([strongSelf.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:didMoveToIndexPath:)]) {
            [strongSelf.dataSource collectionView:strongSelf.collectionView itemAtIndexPath:previousIndexPath didMoveToIndexPath:newIndexPath];
        }
    }];
}

- (void)invalidatesScrollTimer {
    if (!self.displayLink.paused) {
        [self.displayLink invalidate];
    }
    self.displayLink = nil;
}

- (id)init {
    if (self = [super init]) {
        [self setDefaults];
        [self addObserver:self forKeyPath:kALCollectionViewKeyPath options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setDefaults];
        [self addObserver:self forKeyPath:kALCollectionViewKeyPath options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)dealloc {
    [self invalidatesScrollTimer];
    [self tearDownCollectionView];
    [self removeObserver:self forKeyPath:kALCollectionViewKeyPath];
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    if ([layoutAttributes.indexPath isEqual:self.selectedItemIndexPath]) {
        layoutAttributes.hidden = YES;
    }
}

- (void)setupScrollTimerInDirection:(ALScrollingDirection)direction {
    if (!self.displayLink.paused) {
        ALScrollingDirection oldDirection = [self.displayLink.al_userInfo[kALScrollingDirectionKey] integerValue];
        
        if (direction == oldDirection) {
            return;
        }
    }
    
    [self invalidatesScrollTimer];
    
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleScroll:)];
    self.displayLink.al_userInfo = @{ kALScrollingDirectionKey : @(direction) };
    
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (id<ALReorderCollectionViewLayoutDataSource>)dataSource {
    return (id<ALReorderCollectionViewLayoutDataSource>)self.collectionView.dataSource;
}

- (id<ALReorderCollectionViewLayoutDelegateFlowLayout>)delegate {
    return (id<ALReorderCollectionViewLayoutDelegateFlowLayout>)self.collectionView.delegate;
}

#pragma mark - Target / Action methods

- (void)handleScroll:(CADisplayLink *)displayLink {
    ALScrollingDirection direction = (ALScrollingDirection)[displayLink.al_userInfo[kALScrollingDirectionKey] integerValue];
    if (direction == ALScrollingDirectionUnknow) {
        return;
    }
    CGSize frameSize = self.collectionView.bounds.size;
    CGSize contentSize = self.collectionView.contentSize;
    CGPoint contentOffset = self.collectionView.contentOffset;
    UIEdgeInsets contentInset = self.collectionView.contentInset;
    CGFloat distince = rint(self.scrollingSpeed * displayLink.duration);
    CGPoint translation = CGPointZero;
    
    switch (direction) {
        case ALScrollingDirectionUp:
        {
            distince = -distince;
            CGFloat minY = 0.0f - contentInset.top;
            
            if ((contentOffset.y + distince) <= minY) {
                distince = -contentOffset.y - contentInset.top;
            }
            
            translation = CGPointMake(0.0f, distince);
        }
            break;
        case ALScrollingDirectionDown:
        {
            CGFloat maxY = MAX(contentSize.height, frameSize.height) - frameSize.height + contentInset.bottom;
            if ((contentOffset.y + distince) >= maxY) {
                distince = maxY - contentOffset.y;
            }
            translation = CGPointMake(0.0f, distince);
        }
            break;
        case ALScrollingDirectionLeft:
        {
            distince = -distince;
            CGFloat minX = 0.0f - contentInset.left;
            if ((contentOffset.x + distince) <= minX) {
                distince = -contentOffset.x - contentInset.left;
            }
            translation = CGPointMake(distince, 0.0f);
        }
            break;
        case ALScrollingDirectionRight:
        {
            CGFloat maxX = MAX(contentSize.width, frameSize.width) - frameSize.width + contentInset.right;
            if ((contentOffset.x + distince) >= maxX) {
                distince = maxX - contentOffset.x;
            }
            translation = CGPointMake(distince, 0.0f);
         }
            break;
        default:
            break;
    }
    
    self.currentViewCenter = AL_CGPointAdd(self.currentViewCenter, translation);
    self.currentView.center = AL_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);
    self.collectionView.contentOffset = AL_CGPointAdd(contentOffset, translation);
}

- (void)hanleLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer {
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            NSIndexPath *currentIndexPath = [self.collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:self.collectionView]];
            
            if ([self.dataSource respondsToSelector:@selector(collectionView:willBeginMoveItemAtIndexPath:)]) {
                [self.dataSource collectionView:self.collectionView willBeginMoveItemAtIndexPath:currentIndexPath];
            }
            
            if ([self.dataSource respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:)] && ![self.dataSource collectionView:self.collectionView canMoveItemAtIndexPath:currentIndexPath]) {
                return;
            }
            self.selectedItemIndexPath = currentIndexPath;
            
            if ([self.delegate respondsToSelector:@selector(collectionView:layout:willBeginDraggingItemAtIndexPath:)]) {
                [self.delegate collectionView:self.collectionView layout:self didBeginDraggingItemAtIndexPath:self.selectedItemIndexPath];
            }
            UICollectionViewCell *collectionViewCell = [self.collectionView cellForItemAtIndexPath:self.selectedItemIndexPath];
            self.currentView = [[UIView alloc] initWithFrame:collectionViewCell.frame];
            
            collectionViewCell.highlighted = YES;
            UIView *highlightedImageView = [collectionViewCell al_snapshotView];
            highlightedImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            highlightedImageView.alpha = 1.0f;
            collectionViewCell.highlighted = NO;
            UIView *imageView = [collectionViewCell al_snapshotView];
            imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            imageView.alpha = 0.0f;
            
            [self.currentView addSubview:imageView];
            [self.currentView addSubview:highlightedImageView];
            [self.collectionView addSubview:self.currentView];
            
            self.currentViewCenter = self.currentView.center;
            
            __weak typeof(self) weakSelf = self;
            [UIView animateWithDuration:0.3f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                __strong typeof(self) strongSelf = weakSelf;
                if (strongSelf) {
                    strongSelf.currentView.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
                    highlightedImageView.alpha = 0.0f;
                    imageView.alpha = 1.0f;
                }
            } completion:^(BOOL finished) {
                __strong typeof(self) strongSelf = weakSelf;
                if (strongSelf) {
                    [highlightedImageView removeFromSuperview];
                    if ([strongSelf.delegate respondsToSelector:@selector(collectionView:layout:didBeginDraggingItemAtIndexPath:)]) {
                        [strongSelf.delegate collectionView:strongSelf.collectionView layout:strongSelf didBeginDraggingItemAtIndexPath:strongSelf.selectedItemIndexPath];
                    }
                }
            }];
            [self invalidateLayout];
        }
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
        {
            NSIndexPath *currentIndexPath = self.selectedItemIndexPath;
            if (currentIndexPath) {
                if ([self.delegate respondsToSelector:@selector(collectionView:layout:willEndDraggingItemAtIndexPath:)]) {
                    [self.delegate collectionView:self.collectionView layout:self willEndDraggingItemAtIndexPath:currentIndexPath];
                }
                self.selectedItemIndexPath = nil;
                self.currentViewCenter = CGPointZero;
                
                UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForItemAtIndexPath:currentIndexPath];
                self.longPressGestureRecognizer.enabled = NO;
                
                __weak typeof(self) weakSelf = self;
                [UIView animateWithDuration:0.3f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                    __strong typeof(self) strongSelf = weakSelf;
                    if (strongSelf) {
                        strongSelf.currentView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                        strongSelf.currentView.center = layoutAttributes.center;
                    }
                } completion:^(BOOL finished) {
                    __strong typeof(self) strongSelf = weakSelf;
                    if (strongSelf) {
                        strongSelf.longPressGestureRecognizer.enabled = YES;
                        [strongSelf.currentView removeFromSuperview];
                        strongSelf.currentView = nil;
                        [strongSelf invalidateLayout];
                        
                        if ([strongSelf.delegate respondsToSelector:@selector(collectionView:layout:didEndDraggingItemAtIndexPath:)]) {
                            [strongSelf.delegate collectionView:strongSelf.collectionView layout:self didEndDraggingItemAtIndexPath:currentIndexPath];
                        }
                    }
                }];
            }
        }
            break;
        default:
            break;
    }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer {
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
            self.panTranslationInCollectionView = [gestureRecognizer translationInView:self.collectionView];
            CGPoint viewCenter = self.currentView.center = AL_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);
            
            [self invalidateLayoutIfNecessary];
            
            switch (self.scrollDirection) {
                case UICollectionViewScrollDirectionVertical:
                {
                    if (viewCenter.y < (CGRectGetMinY(self.collectionView.bounds) + self.scrollingTriggerEdgeInsets.top)) {
                        [self setupScrollTimerInDirection:ALScrollingDirectionUp];
                    }
                    else {
                        if (viewCenter.y > (CGRectGetMaxY(self.collectionView.bounds) - self.scrollingTriggerEdgeInsets.bottom)) {
                            [self setupScrollTimerInDirection:ALScrollingDirectionDown];
                        }
                        else {
                            [self invalidatesScrollTimer];
                        }
                    }
                    break;
                }
                case UICollectionViewScrollDirectionHorizontal:
                {
                    if (viewCenter.x < (CGRectGetMinX(self.collectionView.bounds) + self.scrollingTriggerEdgeInsets.left)) {
                        [self setupScrollTimerInDirection:ALScrollingDirectionLeft];
                    }
                    else {
                        if (viewCenter.x > (CGRectGetMaxY(self.collectionView.bounds) - self.scrollingTriggerEdgeInsets.right)) {
                            [self setupScrollTimerInDirection:ALScrollingDirectionRight];
                        }
                        else {
                            [self invalidatesScrollTimer];
                        }
                    }
                    break;
                }
                default:
                    break;
            }
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
            [self invalidatesScrollTimer];
        default:
            break;
    }
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *layoutAttributesForElementsInRect = [super layoutAttributesForElementsInRect:rect];
    for (UICollectionViewLayoutAttributes *layoutAttributes in layoutAttributesForElementsInRect) {
        switch (layoutAttributes.representedElementCategory) {
            case UICollectionElementCategoryCell:
                [self applyLayoutAttributes:layoutAttributes];
                break;
                
            default:
                break;
        }
    }
    return layoutAttributesForElementsInRect;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *layoutAttributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    switch (layoutAttributes.representedElementCategory) {
        case UICollectionElementCategoryCell:
            [self applyLayoutAttributes:layoutAttributes];
            break;
            
        default:
            break;
    }
    return layoutAttributes;
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([self.panGestureRecognizer isEqual:gestureRecognizer]) {
        return (self.selectedItemIndexPath != nil);
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([self.longPressGestureRecognizer isEqual:gestureRecognizer]) {
        return [self.panGestureRecognizer isEqual:otherGestureRecognizer];
    }
    if ([self.panGestureRecognizer isEqual:gestureRecognizer]) {
        return [self.longPressGestureRecognizer isEqual:otherGestureRecognizer];
    }
    return NO;
}

#pragma mark - KeyValue Observing methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:kALCollectionViewKeyPath]) {
        [self setupCollectionView];
    }
    else {
        [self invalidatesScrollTimer];
        [self tearDownCollectionView];
    }
}

#pragma mark - Notifications

- (void)handleApplicationWillResignActive:(NSNotification *)notification {
    self.panGestureRecognizer.enabled = NO;
    self.panGestureRecognizer.enabled = YES;
}

@end
