//
//  SleepView.h
//  MotionDetector
//
//  Created by Mitsuya.WATANABE on 2015/05/14.
//  Copyright (c) 2015年 Mitsuya.WATANABE. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SleepView : UIView
+ (instancetype)initFromNib;
- (void)updateTimeLabel:(int)time;
@end
