//
//  ImageProcessor.h
//  MotionDetector
//
//  Created by Mitsuya.WATANABE on 2015/05/07.
//  Copyright (c) 2015年 Mitsuya.WATANABE. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <opencv2/opencv.hpp>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ImageProcessor : NSObject

/**
 *  背景差分処理後の画像を取得
    @param sampleBuffer カメラデータ
    @param binaryThreshold 2値化の閾値
    @param sensitiveValue Motionの敏感時計数
    @param diffValue 変化率
 
    @return 背景処理後の画像
 */
- (UIImage *)diffImageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer binaryThreshold:(float)binaryThreshold sensitiveValue:(float)sensitiveValue diffValue:(int *)diffValue;

/**
 *  uiviewから画像を生成する
    @param view 画像化の対象となるview
    
    @return 対象のviewを画像化したUIImage
 */
+ (UIImage *)screenShotImageOnView:(UIView *)view;
@end
