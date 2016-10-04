//
//  VSSpeechSynthesizer
//  Computer Satellite
//
//  Created by E-Liang Tan on 18/8/12.
//  Copyright (c) 2012 E-Liang Tan. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol VSSpeechSynthesizerDelegate <NSObject>
@optional
-(void)speechSynthesizerDidStartSpeaking:(id)speechSynthesizer;
-(void)speechSynthesizer:(id)synthesizer didFinishSpeaking:(BOOL)speaking withError:(id)error;
-(void)speechSynthesizerDidPauseSpeaking:(id)speechSynthesizer;
-(void)speechSynthesizerDidContinueSpeaking:(id)speechSynthesizer;
-(void)speechSynthesizer:(id)synthesizer willSpeakRangeOfSpeechString:(NSRange)speechString;
@end

@interface VSSpeechSynthesizer : NSObject

+ (void)_localeDidChange;
+ (BOOL)isSystemSpeaking;
+ (id)availableLanguageCodes;
+ (id)availableVoicesForLanguageCode:(id)arg1;
+ (id)availableVoices;
- (void)setMaintainInactivePersistentConnection:(BOOL)arg1;
- (void)setMaintainPersistentConnection:(BOOL)arg1;
- (int)footprint;
- (void)setFootprint:(int)arg1;
- (id)voice;
- (void)setVoice:(id)arg1;
- (float)volume;
- (id)setVolume:(float)arg1;
- (float)pitch;
- (id)setPitch:(float)arg1;
- (float)maximumRate;
- (float)minimumRate;
- (id)setRate:(float)arg1;
- (float)rate;
- (id)speechString;
- (BOOL)isSpeaking;
- (id)continueSpeaking;
- (id)pauseSpeakingAtNextBoundary:(int)arg1 synchronously:(BOOL)arg2;
- (id)pauseSpeakingAtNextBoundary:(int)arg1;
- (id)stopSpeakingAtNextBoundary:(int)arg1 synchronously:(BOOL)arg2;
- (id)stopSpeakingAtNextBoundary:(int)arg1;
- (id)startSpeakingAttributedString:(id)arg1 toURL:(id)arg2 withLanguageCode:(id)arg3;
- (id)startSpeakingAttributedString:(id)arg1 toURL:(id)arg2;
- (id)startSpeakingAttributedString:(id)arg1;
- (id)startSpeakingString:(id)arg1 toURL:(id)arg2 withLanguageCode:(id)arg3;
- (id)startSpeakingString:(id)arg1 attributedString:(id)arg2 toURL:(id)arg3 withLanguageCode:(id)arg4;
- (id)startSpeakingString:(id)arg1 withLanguageCode:(id)arg2;
- (id)startSpeakingString:(id)arg1 toURL:(id)arg2;
- (id)startSpeakingString:(id)arg1;
- (void)setDelegate:(id)arg1;
- (void)dealloc;
- (id)initForInputFeedback;
- (id)init;

@end
