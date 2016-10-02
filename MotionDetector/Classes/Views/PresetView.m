//
//  PresetView.m
//  MotionDetector
//
//  Created by Mitsuya.WATANABE on 2015/05/07.
//  Copyright (c) 2015年 Mitsuya.WATANABE. All rights reserved.
//

#import "PresetView.h"
#import "CommonFunction.h"

@interface PresetView() <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *dataSource;
@property (strong, nonatomic) NSArray *originalDataSource;
@end

@implementation PresetView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


+ (instancetype)initFromNib {
    // xib ファイルから PresetView のインスタンスを得る
    UINib *nib = [UINib nibWithNibName:@"PresetView" bundle:nil];
    PresetView *view = [nib instantiateWithOwner:self options:nil][0];
    return view;
}

- (void)initializeWithDataSource {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.originalDataSource = [CommonFunction contentFilesPathInDirectory];
    // ファイル名だけの配列を作る
    self.dataSource = [self trimFileNameFromFilePathList:self.originalDataSource];
    NSLog(@"dataSource = %@", self.dataSource);
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    [self.tableView reloadData];
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.text = self.dataSource[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(selectedPresetSound:)])
        [self.delegate selectedPresetSound:self.originalDataSource[indexPath.row]];
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (NSArray *)trimFileNameFromFilePathList:(NSArray *)original {
    NSMutableArray *fileNameList = [NSMutableArray arrayWithCapacity:original.count];
    
    for (NSString *filePath in original) {
        NSArray *array = [filePath componentsSeparatedByString:@"/"];
        [fileNameList addObject:array[array.count - 1]];
    }
    
    return fileNameList;
}

@end
