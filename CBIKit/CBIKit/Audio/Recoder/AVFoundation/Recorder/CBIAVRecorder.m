//
//  CBIAVRecorder.m
//  CBIKit
//
//  Created by Quinn Von on 2020/1/19.
//  Copyright © 2020 Better. All rights reserved.
//

#import "CBIAVRecorder.h"
#import "CBICAFToMP3.h"
#import <AVFoundation/AVFoundation.h>

#define isValidString(string)               (string && [string isEqualToString:@""] == NO)
#define SAMEPLE_RATE 44100
#define ENCODE_MP3    1

@interface CBIAVRecorder()<AVAudioRecorderDelegate>
@property (nonatomic, strong) AVAudioRecorder *audioRecorder;
@property (nonatomic,strong) NSString *mp3Path;
@property (nonatomic,strong) NSString *cafPath;//caf 与 wav 相同，都包含pcm

@end

@implementation CBIAVRecorder
/**
 *  获得录音机对象
 *
 *  @return 录音机对象
 */
- (AVAudioRecorder *)audioRecorder{
    if (!_audioRecorder) {
        //7.0第一次运行会提示，是否允许使用麦克风
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSError *sessionError;
        //AVAudioSessionCategoryPlayAndRecord用于录音和播放
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
        if(session == nil)
            NSLog(@"Error creating session: %@", [sessionError description]);
        else
            [session setActive:YES error:nil];
        
        //创建录音文件保存路径
        NSURL *url= [self getSavePath];
        //创建录音格式设置
        NSDictionary *setting = [self getAudioSetting];
        //创建录音机
        NSError *error=nil;
        _audioRecorder = [[AVAudioRecorder alloc]initWithURL:url settings:setting error:&error];
        _audioRecorder.delegate=self;
        _audioRecorder.meteringEnabled=YES;//如果要监控声波则必须设置为YES
        [_audioRecorder prepareToRecord];
        if (error) {
            NSLog(@"创建录音机对象时发生错误，错误信息：%@",error.localizedDescription);
            return nil;
        }
    }
    return _audioRecorder;
}


/**
 *  取得录音文件设置
 *
 *  @return 录音设置
 */
- (NSDictionary *)getAudioSetting{
    NSMutableDictionary *dicM = [NSMutableDictionary dictionary];
    [dicM setObject:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
    [dicM setObject:@(SAMEPLE_RATE) forKey:AVSampleRateKey];
    [dicM setObject:@(2) forKey:AVNumberOfChannelsKey];         //通道数要转换成MP3格式必须为双通道
    [dicM setObject:@(16) forKey:AVLinearPCMBitDepthKey];       //越大越精细，2^16 = 65536,在坐标轴上表示单位长度
    [dicM setObject:[NSNumber numberWithInt:AVAudioQualityMin] forKey:AVEncoderAudioQualityKey];
    return dicM;
}

/**
 *  取得录音文件保存路径
 *
 *  @return 录音文件路径
 */
-(NSURL *)getSavePath{
    //  在Documents目录下创建一个名为FileData的文件夹
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject] stringByAppendingPathComponent:@"AudioData"];
    NSLog(@"%@",path);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = FALSE;
    BOOL isDirExist = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    if(!(isDirExist && isDir))
        
    {
        BOOL bCreateDir = [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        if(!bCreateDir){
            NSLog(@"创建文件夹失败！");
        }
        NSLog(@"创建文件夹成功，文件路径%@",path);
    }
    NSString *fileName = @"record";
    NSString *cafFileName = [NSString stringWithFormat:@"%@.caf", fileName];
    NSString *mp3FileName = [NSString stringWithFormat:@"%@.mp3", fileName];
    
    NSString *cafPath = [path stringByAppendingPathComponent:cafFileName];
    NSString *mp3Path = [path stringByAppendingPathComponent:mp3FileName];
    
    self.mp3Path = mp3Path;
    self.cafPath = cafPath;
    
    NSLog(@"file path:%@",cafPath);
    
    NSURL *url=[NSURL fileURLWithPath:cafPath];
    return url;
}
- (void)cleanCafFile {
    
    if (isValidString(self.cafPath)) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir = FALSE;
        BOOL isDirExist = [fileManager fileExistsAtPath:self.cafPath isDirectory:&isDir];
        if (isDirExist) {
            [fileManager removeItemAtPath:self.cafPath error:nil];
            NSLog(@"  xxx.caf  file   already delete");
        }
    }
}

- (void)cleanMp3File {
    
    if (isValidString(self.mp3Path)) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir = FALSE;
        BOOL isDirExist = [fileManager fileExistsAtPath:self.mp3Path isDirectory:&isDir];
        if (isDirExist) {
            [fileManager removeItemAtPath:self.mp3Path error:nil];
            NSLog(@"  xxx.mp3  file   already delete");
        }
    }
}

- (void)convertMp3 {
    
    
        [[CBICAFToMP3 sharedInstance] conventToMp3WithCafFilePath:self.cafPath
                                                           mp3FilePath:self.mp3Path
                                                            sampleRate:SAMEPLE_RATE callback:^(BOOL result)
        {
            NSLog(@"---- 转码完成  --- result %d  ---- ", result);
        }];;
 

}
- (void)recored{
    
    // 重置录音机
    if (_audioRecorder) {
        [self cleanMp3File];
        [self cleanCafFile];
        _audioRecorder = nil;
    }
    
    if (![self.audioRecorder isRecording]) {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSError *sessionError;
        //AVAudioSessionCategoryPlayAndRecord用于录音和播放
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
        if(session == nil)
            NSLog(@"Error creating session: %@", [sessionError description]);
        else
            [session setActive:YES error:nil];

        [self.audioRecorder record];

         NSLog(@"录音开始");
        
#if ENCODE_MP3
         [[CBICAFToMP3 sharedInstance] conventToMp3WithCafFilePath:self.cafPath
                                                           mp3FilePath:self.mp3Path
                                                            sampleRate:SAMEPLE_RATE
                                                              callback:^(BOOL result)
         {
             if (result) {
                 NSLog(@"mp3 file compression sucesss");
             }
         }];
#endif
        
    } else {
        
        NSLog(@"is  recording now  ....");
    }

}
- (void)stopRecord {
 
    if ([self.audioRecorder isRecording]) {
        NSLog(@"完成");
        [self.audioRecorder stop];
    }

#if !ENCODE_MP3
    [CBIWAVToMP3 conventToMp3WithCafFilePath:self.cafPath
                                      mp3FilePath:self.mp3Path
                                       sampleRate:ETRECORD_RATE
                                         callback:^(BOOL result) {
                                             NSLog(@"转码结果 ------ %d", result);
    }];
    
#endif
}

/* audioRecorderDidFinishRecording:successfully: is called when a recording has been finished or stopped. This method is NOT called if the recorder is stopped due to an interruption. */
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    if (flag) {
        NSLog(@"----- 录音  完毕");
        
#if ENCODE_MP3
        [[CBICAFToMP3 sharedInstance] sendEndRecord];;
#endif
        
    }
}

@end
