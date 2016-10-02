//
//  CommonFunction.m
//  MotionDetector
//
//  Created by Mitsuya.WATANABE on 2015/05/08.
//  Copyright (c) 2015年 Mitsuya.WATANABE. All rights reserved.
//

#import "CommonFunction.h"
static const NSString *kDirectoryHeaderPath = @"/Assets/";
static NSString *kUserDefaultsKey = @"soundFilePath";

@implementation CommonFunction

+ (NSArray *)contentFilesPathInDirectory {
    NSMutableArray *result = [NSMutableArray array];
    NSArray *files = nil;
    
    NSFileManager *filemanager = [[NSFileManager alloc] init];
    NSString *directoryPath = [[NSBundle mainBundle] resourcePath];
    directoryPath = [directoryPath stringByAppendingFormat:@"%@%@",
                     kDirectoryHeaderPath,
                     @"Sounds"];
    files = [filemanager contentsOfDirectoryAtPath:directoryPath error:nil];
    for (int i = 0; i < [files count]; i++) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", directoryPath, files[i]];
        BOOL isDir;
        if ([filemanager fileExistsAtPath:filePath isDirectory:&isDir] && !isDir) {
            [result addObject:filePath];
        } else {
            NSLog(@"This is not a file path");
        }
    }
    filemanager = nil;
    return result;
}

+ (void)saveSoundFilePath:(NSString *)filePath {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:filePath forKey:kUserDefaultsKey];
    [defaults synchronize];
}

+ (NSString *)getSoundFilePath {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *data = [defaults stringForKey:kUserDefaultsKey];

    if (!data) {
        data = [[NSBundle mainBundle] pathForResource:@"default" ofType:@"mp3"];
    }
    return data;
}

@end
