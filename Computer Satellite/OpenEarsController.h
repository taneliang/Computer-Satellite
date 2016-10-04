//
//  OpenEarsController.h
//  Computer Satellite
//
//  Created by E-Liang Tan on 18/8/12.
//  Copyright (c) 2012 E-Liang Tan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenEars/OpenEarsEventsObserver.h>

@protocol OpenEarsControllerDelegate;

@interface OpenEarsController : NSObject <OpenEarsEventsObserverDelegate>

@property (nonatomic, assign) id<OpenEarsControllerDelegate> delegate;

// Vocabulary and activationKeyword must be fully capitalized.
@property (nonatomic, strong, readonly) NSArray *vocabulary;
@property (nonatomic, strong, readonly) NSString *JGSFGrammarFilePath;
- (BOOL)loadVocabularyList:(NSArray *)vocabulary withGrammar:(NSString *)JGSFGrammarFilePath; // Use this to set vocabulary.
@property (nonatomic, strong) NSString *activationKeyword; // activationKeyword is used similarly to the "Computer" keyword in Star Trek. Must be in the vocabulary list already.
@property (nonatomic) NSTimeInterval silenceTimeout; // After activationKeyword has been recognized, all recognized phrases will be passed on to the delegate. After a certain time of silence (silenceTimeout), the controller will be deactivated.

- (void)beginListening;
- (void)resumeListening;
- (void)suspendListening;
- (void)updateLanguageModel;
@property (nonatomic, readonly) BOOL activated;

- (void)invalidateTimeoutTimer;
- (void)reinitializeTimeoutTimer;

@end

@protocol OpenEarsControllerDelegate <NSObject>
@optional

- (void)openEarsControllerDidStartCalibration:(OpenEarsController *)controller;
- (void)openEarsControllerDidEndCalibration:(OpenEarsController *)controller;

- (void)openEarsControllerDidStartListening:(OpenEarsController *)controller;
- (void)openEarsControllerDidSuspendRecognition:(OpenEarsController *)controller;
- (void)openEarsControllerDidResumeRecognition:(OpenEarsController *)controller;

- (void)openEarsController:(OpenEarsController *)controller didRecognizeActivationKeyword:(NSString *)keyword withText:(BOOL)withText;
- (void)openEarsController:(OpenEarsController *)controller didRecognizeText:(NSString *)text; // This will only be called after activation keyword is recognized.

- (void)openEarsControllerDidTimeout:(OpenEarsController *)controller;

@end
