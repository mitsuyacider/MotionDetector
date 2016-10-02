//
//  CommonFunction.h
//  MotionDetector
//
//  Created by Mitsuya.WATANABE on 2015/05/08.
//  Copyright (c) 2015年 Mitsuya.WATANABE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CommonFunction : NSObject

/**
 *  サウンドファイルリストを取得する

    @return サウンドファイルリスト
 */
+ (NSArray *)contentFilesPathInDirectory;

/**
 *  保存してあるサウンドファイルパスを取得する

    @return サウンドファイル名
 */
+ (NSString *)getSoundFilePath;


/**
 *  再生に使用しているサウンドファイルを取得する
    @param filePath 再生するファイルパスを保存
 */
+ (void)saveSoundFilePath:(NSString *)filePath;
@end
