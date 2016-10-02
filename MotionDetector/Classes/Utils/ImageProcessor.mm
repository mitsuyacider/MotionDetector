//
//  ImageProcessor.m
//  MotionDetector
//
//  Created by Mitsuya.WATANABE on 2015/05/07.
//  Copyright (c) 2015年 Mitsuya.WATANABE. All rights reserved.
//

#import "ImageProcessor.h"

using namespace cv;
using namespace std;

@implementation ImageProcessor {
    cv::Mat matCaptured_;
}

+ (UIImage *)screenShotImageOnView:(UIView *)view {
    // 新しいコンテキストを作成
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    UIGraphicsBeginImageContext(screenRect.size);
    
    // カレントコンテキストを取得
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // 黒で塗り潰す
    [[UIColor blackColor] set];
    CGContextFillRect(context, screenRect);
    
    // 対象ビューのレイヤーをカレントコンテキストに描画
    [view.layer renderInContext:context];
    
    // カレントコンテキストの画像を取得
    UIImage *screenImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return screenImage;
}

- (UIImage *)diffImageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer binaryThreshold:(float)binaryThreshold sensitiveValue:(float)sensitiveValue diffValue:(int *)diffValue {
    
    UIImage *result = nil;
    cv::Mat matCaptured = newCvMatSingleChannelFromSampleBufferRef(sampleBuffer);
    Mat dst, diff;
    
    if (!matCaptured_.empty()) {
        vector<cv::Point> contour;
        Mat bgMat = matCaptured_;
        //背景画像との差分を取得
        absdiff(matCaptured, bgMat, diff);
        //二値化画像化
        threshold(diff, dst, binaryThreshold, 255, THRESH_BINARY);
        Mat resultCropped;
        Scalar cvColor(0, 255, 255);
        // Maximum deviation of the image, the higher the value, the more motion is allowed
        *diffValue = detectMotion(dst, diff, resultCropped,  0, matCaptured.cols, 0, matCaptured.rows, sensitiveValue, cvColor);
        
        result = [self cvtUIImageFromCvMat:dst];
    }

    matCaptured_ = matCaptured;
    return result;
}

// @see https://blog.cedric.ws/opencv-simple-motion-detection
inline int detectMotion(const Mat & motion, Mat & result, Mat & result_cropped,
                        int x_start, int x_stop, int y_start, int y_stop,
                        int max_deviation,
                        Scalar & color) {
    // calculate the standard deviation
    Scalar mean, stddev;
    meanStdDev(motion, mean, stddev);
    // if not to much changes then the motion is real (neglect agressive snow, temporary sunlight)
    if(stddev[0] < max_deviation) {
        int number_of_changes = 0;
        int min_x = motion.cols, max_x = 0;
        int min_y = motion.rows, max_y = 0;
        // loop over image and detect changes
        for(int j = y_start; j < y_stop; j+=2) { // height
            for(int i = x_start; i < x_stop; i+=2) { // width
                // check if at pixel (j,i) intensity is equal to 255
                // this means that the pixel is different in the sequence
                // of images (prev_frame, current_frame, next_frame)
                if(motion.at<int>(j, i) == 255) {
                    number_of_changes++;
                    if(min_x > i) min_x = i;
                    //                    if(max_x > j) min_y = j;
                    if(max_x < j) min_y = j;
                    if(max_y < 0) min_x -= 10;
                    if(min_y-10 > 0) min_y -= 10;
                    if(max_x+10 < result.cols-1) max_x += 10;
                    if(max_y+10 < result.rows-1) max_y += 10;
                    // draw rectangle round the changed pixel
                    cv::Point x(min_x,min_y);
                    cv::Point y(max_x,max_y);
                    cv::Rect rect(x,y);
                    Mat cropped = result(rect);
                    cropped.copyTo(result_cropped);
                    rectangle(result,rect,color,1);
                }
            }
        }
        return number_of_changes;
    }
    
    return 0;
    
}

- (UIImage *)cvtUIImageFromCvMat:(cv::Mat)mat {
    size_t width = mat.cols;
    size_t height = mat.rows;
    size_t bytesPerRow = mat.step;
    uchar *data = mat.data;
    
    CGColorSpaceRef colorSpace;
    CGContextRef context;
    if (mat.channels() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
        context = CGBitmapContextCreate(data, width, height, 8, bytesPerRow, colorSpace,
                                        kCGBitmapByteOrderDefault| kCGImageAlphaNone);
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        context = CGBitmapContextCreate(data, width, height, 8, bytesPerRow, colorSpace,
                                        kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst);
    }
    CGColorSpaceRelease(colorSpace);
    
    CGImageRef imageRef;
    UIImage *returnImage;
    imageRef = CGBitmapContextCreateImage(context);
    returnImage = [UIImage imageWithCGImage:imageRef
                                      scale:1.0f
                                orientation:UIImageOrientationUp];
    CGImageRelease(imageRef);
    CGContextRelease(context);
    
    return returnImage;
}

- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width       = CVPixelBufferGetWidth(imageBuffer);
    size_t height      = CVPixelBufferGetHeight(imageBuffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef cgImage = CGBitmapContextCreateImage(newContext);
    UIImage *uiImage = [UIImage imageWithCGImage:cgImage scale:1.0f orientation:UIImageOrientationRight];
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(cgImage);
    
    return uiImage;
}

- (cv::Mat)matFromUIImage:(UIImage *)image {
    CGImageRef imageRef = image.CGImage;
    cv::Mat mat = cv::Mat( image.size.height, image.size.width, CV_8UC4 );
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef contextRef;
    contextRef = CGBitmapContextCreate(mat.data,
                                       mat.cols,
                                       mat.rows,
                                       8,
                                       mat.step,
                                       colorSpace,
                                       kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
    CGContextDrawImage(contextRef,
                       CGRectMake(0, 0, image.size.width, image.size.height),
                       imageRef);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    cv::Mat ret = cv::Mat( image.size.width, image.size.height, CV_8UC4 );
    cv::cvtColor(mat, ret, CV_RGBA2BGR);
    return ret;
}

static cv::Mat newCvMatSingleChannelFromSampleBufferRef(CMSampleBufferRef sampleBuffer) {
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    size_t bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
    size_t bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
    size_t bytesPerRowPlane = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    
    char *bufferBaseAddress = (char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    
    cv::Mat mat((int)bufferHeight, (int)bufferWidth,CV_8UC1);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef bufferContext = CGBitmapContextCreate(bufferBaseAddress,
                                                       bufferWidth,
                                                       bufferHeight,
                                                       8,
                                                       bytesPerRowPlane,
                                                       colorSpace,
                                                       kCGImageAlphaNone);
    
    CGImageRef imageRef = CGBitmapContextCreateImage(bufferContext);
    CGContextRelease(bufferContext);
    CGColorSpaceRelease(colorSpace);
    
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    CGContextRef context = CGBitmapContextCreate(mat.data,
                                                 bufferWidth,
                                                 bufferHeight,
                                                 8,
                                                 mat.step,
                                                 colorSpace,
                                                 kCGImageAlphaNone);
    
    CGContextDrawImage(context, CGRectMake(0,0,bufferWidth,bufferHeight), image.CGImage);
    CGContextRelease(context);
    return mat;
    
}
@end
