//
//  DJAudioRecordManager.m
//  DJAudioManager
//
//  Created by Jaesun on 2020/5/13.
//

#import "DJAudioRecordManager.h"
#import <AVKit/AVKit.h>

@interface DJAudioRecordManager()
// 录音
@property (nonatomic, strong) AVAudioRecorder *audioRecorder;
// 录音文件名称
@property (nonatomic, copy) NSString *currenAudioFileName;
// 计时器
@property (nonatomic,nullable) dispatch_queue_t quene;
@property (nonatomic,nullable) dispatch_source_t timer;

@end

@implementation DJAudioRecordManager

static DJAudioRecordManager *manager = nil;
+ (instancetype)shareManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[DJAudioRecordManager alloc] init];
        // 设置AVAudio场景类型 AVAudioSessionCategoryPlayAndRecord 适用于录制、播放
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    });
    return manager;
}

#pragma mark- Public Method
- (NSString *)startRecordWithName:(NSString *)name {
    if (name) {
        self.currenAudioFileName = name;
    }
    if (self.audioRecorder) {
        [self.audioRecorder stop];
        [self.audioRecorder deleteRecording];
    }
    NSString *filePath = [self.audioFilesPath stringByAppendingPathComponent:self.currenAudioFileName];
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:[NSURL URLWithString:filePath] settings:self.recorderSetting error:nil];
    [self.audioRecorder prepareToRecord];
    [self.audioRecorder record];
    [self recordTime];
    return filePath;
}

- (void)cancelRecord {
    if (!self.audioRecorder) {
        return;
    }
    [self.audioRecorder stop];
    [self.audioRecorder deleteRecording];
    self.timer = nil;
    self.quene = nil;
    self.audioRecorder = nil;
}

- (BOOL)changeToPauseOrContinueRecord {
    if (!self.audioRecorder) {
        return NO;
    }
    if (self.audioRecorder.isRecording) {
           [self.audioRecorder pause];
    }
    else {
        [self.audioRecorder record];
    }
    return self.audioRecorder.isRecording;
}

- (void)stopRecordComplete:(void (^)(NSString * _Nullable, NSTimeInterval))complete {
    if (!self.audioRecorder) {
        if (complete) {
           complete(nil, 0);
        }
    }
    if (complete) {
        complete(self.audioRecorder.url.absoluteString,self.audioRecorder.currentTime);
    }
    [self.audioRecorder stop];
    if (self.timer) {
         dispatch_cancel(self.timer);
    }
    self.audioRecorder = nil;
    self.currenAudioFileName = nil;
}

#pragma mark- Private Method
- (void)recordTime {
    if (self.timer) {
        dispatch_cancel(self.timer);
    }
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.quene);
    // 设置时间间隔
    dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(self.timer, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.timeBlock) {
                self.timeBlock(self.audioRecorder.currentTime);
            }
        });
    });
    dispatch_resume(self.timer);
}

#pragma mark- Property Accessor
- (NSDictionary *)recorderSetting {
    if (!_recorderSetting) {
        _recorderSetting = [self defaultRecorderSetting];
    }
    return _recorderSetting;
}

- (NSString *)audioFilesPath {
    if (!_audioFilesPath) {
        _audioFilesPath = [self defaultAudioFilesPath];
    }
    return _audioFilesPath;
}

- (NSString *)currenAudioFileName {
    if (!_currenAudioFileName) {
        _currenAudioFileName = [self defaultCurrentAudioFileName];
    }
    return _currenAudioFileName;
}

// 录音设置
- (NSDictionary *)defaultRecorderSetting {
    NSDictionary *settings = @{
        // 编码格式wav
        AVFormatIDKey:@(kAudioFormatLinearPCM),
        // 采样率
        AVSampleRateKey:@(16000),
        // 通道数
        AVNumberOfChannelsKey:@(1),
        // 录音质量
        AVEncoderAudioQualityKey:@(AVAudioQualityMedium),
        // 位深
        AVLinearPCMBitDepthKey:@(16),
    };
    return settings;
}

- (NSString *)defaultAudioFilesPath {
    // Document文件夹
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) lastObject];
    // 录音文件夹
    NSString *audioFilesPath = [documentPath stringByAppendingPathComponent:@"dj_audios"];
    if (![[NSFileManager defaultManager] isExecutableFileAtPath:audioFilesPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:audioFilesPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return audioFilesPath;
}

- (NSString *)defaultCurrentAudioFileName {
    NSDate *datenow = [NSDate date];
    NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)([datenow timeIntervalSince1970]*1000)];
    return [NSString stringWithFormat:@"%@.wav",timeSp];
}


//- (void)encodePCMData:(void *)pcmData len:(int)len completeBlock:(MP3EncodeCompleteBlock)completeBlock
//{
//    int mp3DataSize = len;
//
//    unsigned char mp3Buffer[mp3DataSize];
//
//    /**
//     这里的len / 2，是因为我们录音数据是char *类型的，一个char占一个字节。而这里要传的数据是short *类型的，一个short占2个字节
//
//     lame_encode_buffer             //录音数据单声道16位整形用这个方法
//     lame_encode_buffer_interleaved //录音数据双声道交错用这个方法
//     lame_encode_buffer_float       //录音数据采样深度32位浮点型用这个方法
//     */
//    int encodedBytes = lame_encode_buffer(lameClient, pcmData, pcmData, len / 2, mp3Buffer, mp3DataSize);
//
//    if (completeBlock)
//    {
//        completeBlock(mp3Buffer,encodedBytes);
//    }
//}

//- (NSString *)changeWavToMp3WithOriginalPath:(NSString*)originalPath{
//    NSString *cachesDir = NSTemporaryDirectory();
//    NSString *timeNow = [EnzoCustomTool TyzReturnTimeNow:@"yyyyMMddHHmmss"];
//    NSString *mp3FilePath = [cachesDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp3",timeNow]];
//    @try {
//        int read, write;
//
//        FILE *pcm = fopen([recorderSavePath cStringUsingEncoding:1], "rb");
//        fseek(pcm, 4*1024, SEEK_CUR);
//        FILE *mp3 = fopen([mp3FilePath cStringUsingEncoding:1], "wb");
//
//        const int PCM_SIZE = 16*1024;
//        const int MP3_SIZE = 16*1024;
//        short int pcm_buffer[PCM_SIZE*2];
//        unsigned char mp3_buffer[MP3_SIZE];
//
//        lame_t lame = lame_init();
//        lame_set_in_samplerate(lame, 44100);
//        lame_set_VBR(lame, vbr_default);
//        lame_init_params(lame);
//
//        do {
//            read = (int)fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
//            if (read == 0)
//                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
//            else
//                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
//
//            fwrite(mp3_buffer, write, 1, mp3);
//
//        } while (read != 0);
//
//        lame_close(lame);
//        fclose(mp3);
//        fclose(pcm);
//    }
//    @catch (NSException *exception) {
//        NSLog(@"%@",[exception description]);
//    }
//    @finally {
//        NSLog(@"MP3转换成功: %@",mp3FilePath);
//        return mp3FilePath;
//    }
//}

@end
