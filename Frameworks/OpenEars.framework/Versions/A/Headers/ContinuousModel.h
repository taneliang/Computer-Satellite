//  OpenEars _version 1.1_
//  http://www.politepix.com/openears
//
//  ContinuousModel.h
//  OpenEars
//
//  ContinuousModel is a class which consists of the continuous listening loop used by Pocketsphinx.
//
//  Copyright Politepix UG (haftungsbeschränkt) 2012. All rights reserved.
//  http://www.politepix.com
//  Contact at http://www.politepix.com/contact
//
//  This file is licensed under the Politepix Shared Source license found in the root of the source distribution.

//  This class is _never_ directly accessed by a project making use of OpenEars.

#import "ContinuousAudioUnit.h"

@interface ContinuousModel : NSObject {

	BOOL exitListeningLoop; // Should we break out of the loop?
	BOOL inMainRecognitionLoop; // Have we entered the recognition loop or are we still setting up or in a state of having exited?
	BOOL thereIsALanguageModelChangeRequest;
	NSString *languageModelFileToChangeTo;
	NSString *dictionaryFileToChangeTo;
    float secondsOfSilenceToDetect;
    PocketsphinxAudioDevice *audioDevice; // The "device", which is actually a struct containing an Audio Unit.
    BOOL returnNbest;
    int nBestNumber;
    int calibrationTime;
}

- (void) listeningLoopWithLanguageModelAtPath:(NSString *)languageModelPath dictionaryAtPath:(NSString *)dictionaryPath languageModelIsJSGF:(BOOL)languageModelIsJSGF; // Start the loop.
- (void) changeLanguageModelToFile:(NSString *)languageModelPathAsString withDictionary:(NSString *)dictionaryPathAsString;

// This is a test method for synchronously running an entire recognition on one single audio file.

- (void) runRecognitionOnWavFileAtPath:(NSString *)wavPath usingLanguageModelAtPath:(NSString *)languageModelPath dictionaryAtPath:(NSString *)dictionaryPath languageModelIsJSGF:(BOOL)languageModelIsJSGF;
    
- (CFStringRef) getCurrentRoute;
- (void) setCurrentRouteTo:(NSString *)newRoute;

- (int) getRecognitionIsInProgress;
- (void) setRecognitionIsInProgressTo:(int)recognitionIsInProgress;

- (int) getRecordData;
- (void) setRecordDataTo:(int)recordData;

- (float) getMeteringLevel;
- (void) setupCalibrationBuffer;
- (void) putAwayCalibrationBuffer;

- (NSArray *)commandArrayForlanguageModel:(NSString *)languageModelPath andDictionaryPath:(NSString *)dictionaryPath isJSGF:(BOOL)languageModelIsJSGF;


@property (nonatomic, assign) BOOL exitListeningLoop; // Should we break out of the loop?
@property (nonatomic, assign) BOOL inMainRecognitionLoop; // Have we entered the recognition loop or are we still setting up or in a state of having exited?
@property (nonatomic, assign) BOOL thereIsALanguageModelChangeRequest;
@property (nonatomic, retain) NSString *languageModelFileToChangeTo;
@property (nonatomic, retain) NSString *dictionaryFileToChangeTo;
@property (nonatomic, assign) float secondsOfSilenceToDetect;
@property (nonatomic, assign) BOOL returnNbest;
@property (nonatomic, assign) int nBestNumber;
@property (nonatomic, assign) int calibrationTime;


@end
