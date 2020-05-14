//
//  DJViewController.m
//  DJAudioManager
//
//  Created by Jae-sun on 05/13/2020.
//  Copyright (c) 2020 Jae-sun. All rights reserved.
//

#import "DJViewController.h"
#import <DJAudioManager/DJAudioRecordManager.h>

@interface DJViewController ()

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@end

@implementation DJViewController
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)playAction:(UIButton *)sender {
    
    [[DJAudioRecordManager shareManager] startRecordWithName:@"doing.wav"];
    [DJAudioRecordManager shareManager].timeBlock = ^(NSTimeInterval currentTime) {
        NSLog(@"%f",currentTime);
        self.timeLabel.text = [NSString stringWithFormat:@"%@",[self timeForamtWithInterval:(int)currentTime]];
    };
}

- (IBAction)pauseAction:(UIButton *)sender {
    BOOL isRecording = [[DJAudioRecordManager shareManager] changeToPauseOrContinueRecord];
    [sender setTitle:isRecording?@"暂停录音":@"继续录音" forState:UIControlStateNormal];
}
    
- (IBAction)endAction:(UIButton *)sender {
    [[DJAudioRecordManager shareManager] stopRecordComplete:^(NSString * _Nullable filePath, NSTimeInterval totalTime) {
        NSLog(@"filePath:%@",filePath);
        NSLog(@"totalTime:%@",[self timeForamtWithInterval:(int)totalTime]);
    }];

}

- (NSString *)timeForamtWithInterval:(NSInteger)interval {
    if (interval <= 0) {
        return @"00:00:00";
    }
    else {
        NSInteger hours = interval / (60 * 60);
        NSInteger minutes = (interval - hours * 60 * 60 ) / 60;
        NSInteger seconds = interval - (hours * 60 * 60) - (minutes * 60);
        return [NSString stringWithFormat:@"%02ld:%02ld:%02ld",(long)hours,(long)minutes,(long)seconds];
    }
}

@end
