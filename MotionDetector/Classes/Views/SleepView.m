//
//  SleepView.m
//  MotionDetector
//
//  Created by Mitsuya.WATANABE on 2015/05/14.
//  Copyright (c) 2015年 Mitsuya.WATANABE. All rights reserved.
//

#import "SleepView.h"
@interface SleepView()
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@end

@implementation SleepView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
+ (instancetype)initFromNib {
    // xib ファイルから PresetView のインスタンスを得る
    UINib *nib = [UINib nibWithNibName:@"SleepView" bundle:nil];
    SleepView *view = [nib instantiateWithOwner:self options:nil][0];
    return view;
}

- (void)updateTimeLabel:(int)time {
    NSString *timeStr = [NSString stringWithFormat:@"%d", time];
    self.timeLabel.text = timeStr;
}
@end
