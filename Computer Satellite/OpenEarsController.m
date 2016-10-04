//
//  OpenEarsController.m
//  Computer Satellite
//
//  Created by E-Liang Tan on 18/8/12.
//  Copyright (c) 2012 E-Liang Tan. All rights reserved.
//

#import "OpenEarsController.h"

#import <OpenEars/PocketsphinxController.h> // Please note that unlike in previous versions of OpenEars, we now link the headers through the framework.
#import <OpenEars/LanguageModelGenerator.h>
#import <OpenEars/OpenEarsLogging.h>

@interface OpenEarsController ()

@property (nonatomic, strong) NSString *lmPath;
@property (nonatomic, strong) NSString *dictionaryPath;

@property (nonatomic, strong) OpenEarsEventsObserver *openEarsEventsObserver;
@property (nonatomic, strong) PocketsphinxController *pocketsphinxController;

@property (nonatomic) BOOL recognizing;
@property (nonatomic) BOOL didTimeoutDuringRecognition;
@property (nonatomic, strong) NSTimer *silenceTimeoutTimer;

@end

@implementation OpenEarsController

- (id)init {
	self = [super init];
	if (self) {
		[self.openEarsEventsObserver setDelegate:self];
		
		[self willChangeValueForKey:@"activated"];
		_activated = NO;
		[self didChangeValueForKey:@"activated"];
		
//		self.silenceTimeoutTimer = nil;
		self.recognizing = NO;
		self.didTimeoutDuringRecognition = NO;
	}
	return self;
}

- (BOOL)loadVocabularyList:(NSArray *)vocabulary withGrammar:(NSString *)JGSFGrammarFilePath {
	LanguageModelGenerator *languageModelGenerator = [[LanguageModelGenerator alloc] init];
	NSError *error = [languageModelGenerator generateLanguageModelFromArray:vocabulary withFilesNamed:@"OpenEarsDynamicGrammar"];
    
	NSDictionary *dynamicLanguageGenerationResultsDictionary = nil;
	if([error code] != noErr) {
		NSLog(@"Dynamic language generator reported error %@", [error description]);
		return NO;
	}
	
	dynamicLanguageGenerationResultsDictionary = [error userInfo];
	self.lmPath = [dynamicLanguageGenerationResultsDictionary objectForKey:@"LMPath"];
	self.dictionaryPath = [dynamicLanguageGenerationResultsDictionary objectForKey:@"DictionaryPath"];
	
	[self willChangeValueForKey:@"vocabulary"];
	_vocabulary = vocabulary;
	[self didChangeValueForKey:@"vocabulary"];
	
	[self willChangeValueForKey:@"JGSFGrammarFilePath"];
	_JGSFGrammarFilePath = JGSFGrammarFilePath;
	[self didChangeValueForKey:@"JGSFGrammarFilePath"];
	
	return YES;
}

- (void)setActivationKeyword:(NSString *)activationKeyword {
	if ([self.vocabulary containsObject:activationKeyword]) {
		[self willChangeValueForKey:@"activationKeyword"];
		_activationKeyword = activationKeyword;
		[self didChangeValueForKey:@"activationKeyword"];
	}
}

- (void)beginListening {
	[self.pocketsphinxController startListeningWithLanguageModelAtPath:self.JGSFGrammarFilePath dictionaryAtPath:self.dictionaryPath languageModelIsJSGF:TRUE];
}

- (void)resumeListening {
	[self.pocketsphinxController resumeRecognition];
}

- (void)suspendListening {
	[self.pocketsphinxController suspendRecognition];
}

- (void)updateLanguageModel {
	[self.pocketsphinxController changeLanguageModelToFile:self.JGSFGrammarFilePath withDictionary:self.dictionaryPath];
}

- (void)invalidateTimeoutTimer {
	[self.silenceTimeoutTimer invalidate];
	self.silenceTimeoutTimer = nil;
//	NSLog(@"Timeout called");
}

- (void)reinitializeTimeoutTimer {
	[self invalidateTimeoutTimer];
	self.silenceTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:self.silenceTimeout target:self selector:@selector(silenceTimeoutTimerDidFire) userInfo:nil repeats:NO];
//	NSLog(@"Reinitialized timer.");
}

#pragma - Accessors

// Lazily allocated PocketsphinxController.
- (PocketsphinxController *)pocketsphinxController {
	if (_pocketsphinxController == nil) {
		_pocketsphinxController = [[PocketsphinxController alloc] init];
		_pocketsphinxController.secondsOfSilenceToDetect = 0.1;
//        _pocketsphinxController.returnNbest = TRUE;
//        _pocketsphinxController.nBestNumber = 5;
	}
	return _pocketsphinxController;
}

// Lazily allocated OpenEarsEventsObserver.
- (OpenEarsEventsObserver *)openEarsEventsObserver {
	if (_openEarsEventsObserver == nil) {
		_openEarsEventsObserver = [[OpenEarsEventsObserver alloc] init];
	}
	return _openEarsEventsObserver;
}

#pragma - Delegate methods

- (void)silenceTimeoutTimerDidFire {
	
	if ([self.silenceTimeoutTimer isValid] == NO) return;
	[self invalidateTimeoutTimer];
	
	if (self.recognizing == YES) {
		self.didTimeoutDuringRecognition = YES;
		return;
	}
	
	[self willChangeValueForKey:@"activated"];
	_activated = NO;
	[self didChangeValueForKey:@"activated"];
	
	if ([self.delegate respondsToSelector:@selector(openEarsControllerDidTimeout:)]) {
		[self.delegate openEarsControllerDidTimeout:self];
	}
}

- (void)pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID {
	NSLog(@"The received hypothesis is %@ with a score of %@ and an ID of %@", hypothesis, recognitionScore, utteranceID);
	
	NSString *text = hypothesis;
	self.recognizing = NO;
	
	if ([hypothesis length] <= 0) {
		if (self.didTimeoutDuringRecognition == YES) [self silenceTimeoutTimerDidFire];
		self.didTimeoutDuringRecognition = NO;
		return;
	}
	
	self.didTimeoutDuringRecognition = NO; // Cancel that since we're going to reset the timer anyway.
	
	if (self.activated == NO) {
		if (![hypothesis hasPrefix:self.activationKeyword]) return;
		
		[self reinitializeTimeoutTimer];
		
		[self willChangeValueForKey:@"activated"];
		_activated = YES;
		[self didChangeValueForKey:@"activated"];
		
		BOOL withText = ![hypothesis isEqualToString:self.activationKeyword];
		if ([self.delegate respondsToSelector:@selector(openEarsController:didRecognizeActivationKeyword:withText:)]) {
			[self.delegate openEarsController:self didRecognizeActivationKeyword:hypothesis withText:withText];
		}
		
		if (!withText) return;
		text = [hypothesis substringFromIndex:[self.activationKeyword length] + 1];
	}
	
	[self reinitializeTimeoutTimer];
	if ([self.delegate respondsToSelector:@selector(openEarsController:didRecognizeText:)]) {
		[self.delegate openEarsController:self didRecognizeText:text];
	}
}

- (void)pocketsphinxDidReceiveNBestHypothesisArray:(NSArray *)hypothesisArray { // Pocketsphinx has an n-best hypothesis dictionary.
//    NSLog(@"hypothesisArray is %@",hypothesisArray);
}

- (void)audioSessionInterruptionDidBegin {
	NSLog(@"AudioSession interruption began."); // Log it.
}

- (void)audioSessionInterruptionDidEnd {
	NSLog(@"AudioSession interruption ended."); // Log it.
    // We're restarting the previously-stopped listening loop.
	[self.pocketsphinxController startListeningWithLanguageModelAtPath:self.lmPath dictionaryAtPath:self.dictionaryPath languageModelIsJSGF:FALSE];
}

- (void)audioInputDidBecomeUnavailable {
	NSLog(@"The audio input has become unavailable"); // Log it.
	[self.pocketsphinxController stopListening]; // React to it by telling Pocketsphinx to stop listening since there is no available input
}

- (void)audioInputDidBecomeAvailable {
	NSLog(@"The audio input is available"); // Log it.
	[self.pocketsphinxController startListeningWithLanguageModelAtPath:self.lmPath dictionaryAtPath:self.dictionaryPath languageModelIsJSGF:FALSE];
}

- (void)audioRouteDidChangeToRoute:(NSString *)newRoute {
	NSLog(@"Audio route change. The new audio route is %@", newRoute); // Log it.
	[self.pocketsphinxController stopListening]; // React to it by telling the Pocketsphinx loop to shut down and then start listening again on the new route
	[self.pocketsphinxController startListeningWithLanguageModelAtPath:self.lmPath dictionaryAtPath:self.dictionaryPath languageModelIsJSGF:FALSE];
}

- (void)pocketsphinxDidStartCalibration {
	if ([self.delegate respondsToSelector:@selector(openEarsControllerDidStartCalibration:)]) {
		[self.delegate openEarsControllerDidStartCalibration:self];
	}
}

- (void)pocketsphinxDidCompleteCalibration {
	if ([self.delegate respondsToSelector:@selector(openEarsControllerDidEndCalibration:)]) {
		[self.delegate openEarsControllerDidEndCalibration:self];
	}
}

- (void)pocketsphinxRecognitionLoopDidStart {
	NSLog(@"Pocketsphinx is starting up."); // Log it.
}

- (void)pocketsphinxDidStartListening {
	if ([self.delegate respondsToSelector:@selector(openEarsControllerDidStartListening:)]) {
		[self.delegate openEarsControllerDidStartListening:self];
	}
}

- (void)pocketsphinxDidDetectSpeech {
//	NSLog(@"Pocketsphinx has detected speech."); // Log it.
	self.recognizing = YES;
}

- (void)pocketsphinxDidDetectFinishedSpeech {
//	NSLog(@"Pocketsphinx has concluded an utterance."); // Log it.
}

- (void)pocketsphinxDidSuspendRecognition {
	if ([self.delegate respondsToSelector:@selector(openEarsControllerDidSuspendRecognition:)]) {
		[self.delegate openEarsControllerDidSuspendRecognition:self];
	}
}
- (void)pocketsphinxDidResumeRecognition {
	if ([self.delegate respondsToSelector:@selector(openEarsControllerDidStartCalibration:)]) {
		[self.delegate openEarsControllerDidStartCalibration:self];
	}
}

@end
