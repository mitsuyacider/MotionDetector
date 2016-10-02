//
//  PresetView.h
//  MotionDetector
//
//  Created by Mitsuya.WATANABE on 2015/05/07.
//  Copyright (c) 2015年 Mitsuya.WATANABE. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PresetViewDelegate <NSObject>
- (void)selectedPresetSound:(NSString *)filePath;
@end


@interface PresetView : UIView
@property (nonatomic, weak) id <PresetViewDelegate> delegate;

/**
 *  インスタンスを生成する
    @return object
 */
+ (instancetype)initFromNib;

/**
 *  初期化
    @param dataSource
 */
- (void)initializeWithDataSource;
@end
