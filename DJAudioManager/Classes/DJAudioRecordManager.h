//
//  DJAudioRecordManager.h
//  DJAudioManager
//
//  Created by Jaesun on 2020/5/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DJAudioRecordManager : NSObject

+ (instancetype)shareManager;
// 录音设置   编码格式、采样率、通道数、录音质量、位深 ，
// 如果为nil 则 默认为：.wav、16000HZ、单通道、质量中等、16位
@property (nonatomic, copy) NSDictionary *recorderSetting;
// 录音文件保存的文件夹
// 默认为 Document/dj_audios/
@property (nonatomic, copy) NSString *audioFilesPath;
@property (nonatomic, copy) void(^timeBlock)(NSTimeInterval currentTime);
// 开始录音
- (NSString *)startRecordWithName:(NSString *)name;
// 取消录音
- (void)cancelRecord;
// 暂停/继续 录音
- (BOOL)changeToPauseOrContinueRecord;
// 结束录音
- (void)stopRecordComplete:(void(^)( NSString * _Nullable filePath, NSTimeInterval totalTime))complete;


@end

NS_ASSUME_NONNULL_END
