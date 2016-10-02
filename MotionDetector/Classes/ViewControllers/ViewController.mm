//
//  ViewController.m
//  MotionDetector
//
//  Created by Mitsuya.WATANABE on 2015/04/29.
//  Copyright (c) 2015年 Mitsuya.WATANABE. All rights reserved.
//

#import "ViewController.h"
#import "ImageProcessor.h"
#import "PresetView.h"
#import "CommonFunction.h"
#import "SleepView.h"

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate, PresetViewDelegate, AVAudioPlayerDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *cameraImageView;
@property (nonatomic, strong) UIImage *capturedImage;
@property (weak, nonatomic) IBOutlet UIView *frameView;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UISlider *thresholdSlider;
@property (weak, nonatomic) IBOutlet UISlider *sensitivitySlider;
@property (weak, nonatomic) IBOutlet UISlider *durationSlider;
@property (nonatomic, strong) ImageProcessor *imageProcessor;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, assign) BOOL showPreset;
@property (nonatomic, strong) PresetView *presetView;
@property (nonatomic, strong) SleepView *sleepView;
@property (nonatomic, assign) BOOL isActiveDisplay;
@property (nonatomic, assign) BOOL canPlaySound;
@property (nonatomic, strong) NSTimer *soundLockTimer;
@property (nonatomic, assign) int longPressCount;
@property (weak, nonatomic) IBOutlet UIView *blackView;
@property (strong, nonatomic) NSArray *audioFilePathList;
@property (weak, nonatomic) IBOutlet UISwitch *randomSwitch;
@end


static const int kDisplaySleepCount = 3;

@implementation ViewController {
    AVCaptureDevice *videoCaptureDevice_;
    AVCaptureSession *captureSession_;
    BOOL isRunning_;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 音声ファイルリストを取得する
    self.audioFilePathList = [CommonFunction contentFilesPathInDirectory];
    
    self.imageProcessor = [[ImageProcessor alloc] init];
    
    // set up capture device.
    [self setupCaptureDevice];
    
    // set up frame view and label.
    self.frameView.layer.borderColor = [[UIColor greenColor] CGColor];
    self.frameView.layer.borderWidth = 1.0;
    self.label.textColor = [UIColor greenColor];
    
    // set up presetview.
    self.presetView = [PresetView initFromNib];
    [self.view addSubview:self.presetView];
    [self.presetView initializeWithDataSource];
    self.presetView.hidden = YES;
    self.presetView.delegate = self;
    
    // set up sleepview.
    self.sleepView = [SleepView initFromNib];
    CGRect frame = self.sleepView.frame;
    frame.origin.y = -frame.size.height;
    self.sleepView.frame = frame;
    [self.view addSubview:self.sleepView];

    // set up audipplayer.
//    [self setupAudioPlayer:[NSURL URLWithString:[CommonFunction getSoundFilePath]]];

    [self setupAudioPlayer:[NSURL URLWithString:self.audioFilePathList[0]]];
    
    // regist gesture recogniezer
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc]
                                                      initWithTarget:self action:@selector(handleLongPressGesture:)];
    [self.view addGestureRecognizer:longPressGesture];
    
    self.blackView.alpha = 0.0;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self startCaptureImage];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupCaptureDevice {
    AVCaptureDevicePosition position = AVCaptureDevicePositionFront;
    
    // デバイス取得
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in videoDevices) {
        if (device.position == position) {
            videoCaptureDevice_ = device;
            break;
        }
    }
    if (videoCaptureDevice_ == nil) {
        NSLog(@"ERROR: No suitable video capture device found");
    }
}

- (void)startCaptureImage {
    // 入力作成
    NSError *error = nil;
    AVCaptureDevice *videoCaptureDevice = videoCaptureDevice_;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:&error];
    if (deviceInput == nil) {
        NSLog(@"ERROR: Unable to create input device: %@", [error localizedDescription]);
    }
    
    // ビデオデータ出力作成
    AVCaptureVideoDataOutput *dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    NSDictionary* settings = @{(id)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]};
    dataOutput.videoSettings = settings;
    [dataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    // セッション作成
    AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
    captureSession.sessionPreset = AVCaptureSessionPreset640x480;
    [captureSession addInput:deviceInput];
    [captureSession addOutput:dataOutput];
    captureSession_ = captureSession;
    
    if ([videoCaptureDevice lockForConfiguration:&error]) {
        
        if ([videoCaptureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            videoCaptureDevice.focusMode = AVCaptureFocusModeLocked; // AVCaptureFocusModeContinuousAutoFocus;
            
        } else if ([videoCaptureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            videoCaptureDevice.focusMode = AVCaptureFocusModeLocked; // AVCaptureFocusModeAutoFocus;
        }
        
        if ([videoCaptureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
            videoCaptureDevice.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
        } else if ([videoCaptureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
            videoCaptureDevice.whiteBalanceMode = AVCaptureWhiteBalanceModeAutoWhiteBalance;
        }
        
        if ([videoCaptureDevice isFlashModeSupported:AVCaptureFlashModeAuto]) {
            videoCaptureDevice.flashMode = AVCaptureFlashModeAuto;
        }
        
        [videoCaptureDevice unlockForConfiguration];
        
    } else {
        NSLog(@"%s|[ERROR] %@", __PRETTY_FUNCTION__, [error localizedDescription]);
    }
    
    // カメラの向きなどを設定する
    [captureSession beginConfiguration];
    
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in [dataOutput connections]) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                videoConnection = connection;
                break;
            }
        }
    }
    
    if ([videoConnection isVideoOrientationSupported]) {
        [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }
    
    [captureSession commitConfiguration];
    [captureSession startRunning];
    
    isRunning_ = YES;
}

- (void)stopRecognition {
    if (isRunning_) {
        [captureSession_ stopRunning];
        captureSession_ = nil;
                
        isRunning_ = NO;
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    __block UIImage *destImage = nil;
    __block ViewController *weakSelf = self;
    int changeValue;
    destImage = [self.imageProcessor diffImageFromSampleBuffer:sampleBuffer binaryThreshold:self.thresholdSlider.value sensitiveValue:self.sensitivitySlider.value diffValue:&changeValue];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (destImage) {
            weakSelf.cameraImageView.image = destImage;
            
            UIColor *color = nil;
            if (changeValue >= 0 && changeValue <= 20) color = [UIColor greenColor];
            else if (changeValue > 20 && changeValue <= 100) color = [UIColor yellowColor];
            else {
                color = [UIColor redColor];
                
                if (weakSelf.canPlaySound) {
                    weakSelf.canPlaySound = NO;
                    [weakSelf torch];
                    [weakSelf.audioPlayer play];
                    NSLog(@"lock sound >> before");
                }
            }
            
            weakSelf.frameView.layer.borderColor = color.CGColor;
            weakSelf.label.textColor = color;
        }
    });
}

#pragma mark - Other
- (void)torch {
    [self stopRecognition];
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [device lockForConfiguration:nil];
    [device setTorchModeOnWithLevel:1.0 error:NULL];
    [device unlockForConfiguration];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self setupCaptureDevice];
        [self startCaptureImage];
    });
}

- (void)unlockPlayingSound {
    __block ViewController *weakSelf = self;
    // ?秒後に処理を実行
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.durationSlider.value * NSEC_PER_SEC));
    dispatch_after(time, dispatch_get_main_queue(), ^{
        NSLog(@"lock sound");
        weakSelf.canPlaySound = YES;
    });
}

- (void)setupAudioPlayer:(NSURL *)url {
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    self.audioPlayer.delegate = self;
    self.canPlaySound = YES;
}

- (void)presetViewIsHidden:(BOOL)hidden {
    float fromValue = hidden ? 0.08 : 1.0;
    float toValue = hidden ? 1.0 : 0.08;
    CABasicAnimation *myAnimation = [CABasicAnimation animationWithKeyPath:@"rasterizationScale"];
    self.frameView.layer.shouldRasterize = !hidden;
    self.presetView.hidden = hidden;
    
    myAnimation.fromValue = @(fromValue);
    myAnimation.toValue = @(toValue);
    myAnimation.duration = 0.15;
    //アニメーション終了時にエフェクトが元に戻らないようにしておく
    myAnimation.removedOnCompletion = NO;
    myAnimation.fillMode = kCAFillModeForwards;
    
    self.showPreset = hidden;
    [self.frameView.layer addAnimation:myAnimation forKey:@"myAnimation"];

}

- (void)sleepViewIsHidden:(BOOL)hidden {
    __block CGRect frame = self.sleepView.frame;
    float toValue = hidden ? -frame.size.height : 0.0;
    [UIView animateWithDuration:0.3 animations:^{
        frame.origin.y = toValue;
        self.sleepView.frame = frame;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)displayIsHidden:(BOOL)hidden {
    float toValue = hidden ? 1.0 : 0.0;
    [UIView animateWithDuration:0.5 animations:^{
        self.blackView.alpha = toValue;
    } completion:^(BOOL finished) {
    }];
}

- (void)updateTimeLabel {
    [self.sleepView updateTimeLabel:kDisplaySleepCount - self.longPressCount];
}

- (void)refreshAudioFile {
    // ランダムindexを取得する
    int random = (int)arc4random_uniform((int)self.audioFilePathList.count);
    [self.audioPlayer stop];
    self.audioPlayer = nil;
    [self setupAudioPlayer:[NSURL URLWithString:self.audioFilePathList[random]]];
}

#pragma mark - AVPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NSLog(@"did finish playing");
    [self unlockPlayingSound];
    
    if (self.randomSwitch.on) {
        // 音声ファイルを変更する
        [self refreshAudioFile];        
    }
}

#pragma mark - PresetViewDelegate
- (void)selectedPresetSound:(NSString *)filePath {
    [self.audioPlayer stop];
    self.audioPlayer = nil;
    
    [self setupAudioPlayer:[NSURL URLWithString:filePath]];
    [self presetViewIsHidden:YES];
    
    [CommonFunction saveSoundFilePath:filePath];
}

#pragma mark - IBAction
- (IBAction)tappedCaptureButton {
    self.capturedImage = self.cameraImageView.image;
}

- (IBAction)tappedPresetButton {
    [self presetViewIsHidden:NO];
}

#pragma mark - GestureRecognizer
- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer {
    switch (gestureRecognizer.state) {
            
        case UIGestureRecognizerStateBegan:
            if (self.blackView.alpha == 1.0) {
                [self displayIsHidden:NO];
            } else {
                self.longPressCount = 0;
                [self updateTimeLabel];
                [self performSelector:@selector(repeat:) withObject:nil afterDelay:0.1];
                [self sleepViewIsHidden:NO];
            }
            break;
            
        case UIGestureRecognizerStateChanged:
            break;
            
        case UIGestureRecognizerStateEnded:
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(repeat:) object:nil];
            [self sleepViewIsHidden:YES];
            break;
            
        default:
            break;
    }
}

- (void)repeat:(id)sender {
    //  リピート処理を記述
    if (self.longPressCount == kDisplaySleepCount) {
        [self sleepViewIsHidden:YES];
        [self displayIsHidden:YES];
    } else {
        // 0.5秒後に再度呼出
        [self updateTimeLabel];
        [self performSelector:@selector(repeat:) withObject:nil afterDelay:1.0];
        self.longPressCount++;
    }

}

@end
