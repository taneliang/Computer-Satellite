//
//  ViewController.m
//  Computer Satellite
//
//  Created by E-Liang Tan on 18/8/12.
//  Copyright (c) 2012 E-Liang Tan. All rights reserved.
//

#import "ViewController.h"

@interface NSString (ComputerCommandAdditions)
- (NSString *)firstWordCapitalizedString;
@end

@implementation NSString (ComputerCommandAdditions)

- (NSString *)firstWordCapitalizedString {
	NSMutableArray *components = [NSMutableArray arrayWithArray:[self componentsSeparatedByString:@" "]];
	components[0] = [components[0] capitalizedString];
	return [components componentsJoinedByString:@" "];
}

@end

@interface ViewController ()

@end

@implementation ViewController

- (FliteController *)flite {
	if (_flite == nil) {
		_flite = [[FliteController alloc] init];
	}
	return _flite;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	self.speechSynthesizer = [[VSSpeechSynthesizer alloc] init];
	[self.speechSynthesizer setDelegate:self];
	
	NSError *error = nil;
	self.errorSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"error" withExtension:@"caf"] error:&error];
	self.activatedSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"activated" withExtension:@"caf"] error:&error];
	self.acknowledgedSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"acknowledged" withExtension:@"caf"] error:&error];
	self.acknowledgedTwoSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"acknowledged_2" withExtension:@"caf"] error:&error];
	if (error) {
		NSLog(@"Well one or more of those sounds couldn't load. lol. %@", error);
	}
	self.errorSoundPlayer.delegate = self;
	self.activatedSoundPlayer.delegate = self;
	self.acknowledgedSoundPlayer.delegate = self;
	self.acknowledgedTwoSoundPlayer.delegate = self;
	
	NSArray *languageArray = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Vocabulary" ofType:@"plist"]];
	self.openEarsController = [[OpenEarsController alloc] init];
	[self.openEarsController setDelegate:self];
	[self.openEarsController loadVocabularyList:languageArray withGrammar:[[NSBundle mainBundle] pathForResource:@"vocabulary" ofType:@"gram"]];
	[self.openEarsController setActivationKeyword:@"COMPUTER"];
	[self.openEarsController setSilenceTimeout:5];
	[self.openEarsController beginListening];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)speechSynthesizerDidStartSpeaking:(id)speechSynthesizer {
	NSLog(@"Did start speaking");
	[self.openEarsController suspendListening];
	[self.openEarsController invalidateTimeoutTimer];
}

-(void)speechSynthesizer:(id)synthesizer didFinishSpeaking:(BOOL)speaking withError:(id)error {
	NSLog(@"Did finish speaking %@ %d %@", synthesizer, speaking, error);
	[self.openEarsController resumeListening];
	[self.openEarsController reinitializeTimeoutTimer];
}

- (void)openEarsControllerDidStartCalibration:(OpenEarsController *)controller {
	NSLog(@"hey there");
}

- (void)openEarsControllerDidEndCalibration:(OpenEarsController *)controller {
	NSLog(@"ho there");
}

- (void)openEarsControllerDidStartListening:(OpenEarsController *)controller {
}

- (void)openEarsController:(OpenEarsController *)controller didRecognizeActivationKeyword:(NSString *)keyword withText:(BOOL)withText {
	[self.openEarsController suspendListening];
	if (!withText) [self.activatedSoundPlayer play];
	NSLog(@"didRecognizeActivationKeyword: %@ with following text: %d", keyword, withText);
	[self.activationState setOn:YES animated:YES];
}

- (void)openEarsController:(OpenEarsController *)controller didRecognizeText:(NSString *)text {
	__block AVAudioPlayer *player = self.acknowledgedTwoSoundPlayer;
	
	static NSString *IPAddress = @"10.0.1.9";
	
	NSString *speechString = nil;
	self.timeLabel.text = [[NSDate date] description];
	self.saidLabel.text = [[text lowercaseString] firstWordCapitalizedString];
	
	if ([text isEqualToString:@"WHAT IS THE TIME"]) {
		[self.openEarsController suspendListening];
		[player play];
		NSDate *currentDate = [NSDate date];
		NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:currentDate];
		
		NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
		[numberFormatter setMinimumIntegerDigits:2];
		[numberFormatter setMaximumIntegerDigits:2];
		[numberFormatter setNumberStyle:NSNumberFormatterNoStyle];
		
		NSString *timeString = [NSString stringWithFormat:@"%@ %@", [numberFormatter stringFromNumber:[NSNumber numberWithInteger:[dateComponents hour]]], [numberFormatter stringFromNumber:[NSNumber numberWithInteger:[dateComponents minute]]]];
		NSLog(@"%@", timeString);
		speechString = [NSString stringWithFormat:@"The time is %@ hours", timeString];
		self.statusLabel.text = @"Success";
		NSTimeInterval delay = 0;
		if (player.playing) delay = player.duration - player.currentTime;
		[self.speechSynthesizer performSelector:@selector(startSpeakingString:) withObject:speechString afterDelay:delay];
		self.messageLabel.text = speechString;
		return;
	}
	else if ([text isEqualToString:@"WHAT IS THE DATE"]) {
		[self.openEarsController suspendListening];
		[player play];
		NSDate *currentDate = [NSDate date];
		NSString *dateString = [NSDateFormatter localizedStringFromDate:currentDate dateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterNoStyle];
		speechString = [NSString stringWithFormat:@"It is %@", dateString];
		self.statusLabel.text = @"Success";
		NSTimeInterval delay = 0;
		if (player.playing) delay = player.duration - player.currentTime;
		[self.speechSynthesizer performSelector:@selector(startSpeakingString:) withObject:speechString afterDelay:delay];
		self.messageLabel.text = speechString;
		return;
	}
	
	NSMutableDictionary *queryDictionary = [NSMutableDictionary dictionary];
	queryDictionary[@"cmd"] = @"voice_ctrl";
	queryDictionary[@"q"] = text;
	if ([text isEqualToString:@"UPDATE LIST OF PROGRAMS"]) queryDictionary[@"cmd"] = @"get_program_list", [queryDictionary removeObjectForKey:@"q"];
	NSData *JSONQueryData = [[[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:queryDictionary options:0 error:nil] encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""] dataUsingEncoding:NSUTF8StringEncoding];
	NSURL *queryURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/ccmd.php", IPAddress]];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:queryURL];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:JSONQueryData];
	
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
		NSString *speechString = nil;
		NSLog(@"%@ %@ %@", response, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding], error);
		NSDictionary *returnDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
		
		player = self.errorSoundPlayer;
		if (error) {
			[self.openEarsController suspendListening];
			[player play];
			return;
		}
		
		if ([[returnDictionary allKeys] containsObject:@"sound"]) {
			if ([returnDictionary[@"sound"] isEqualToString:@"acknowledged_one"]) player = self.acknowledgedSoundPlayer;
			if ([returnDictionary[@"sound"] isEqualToString:@"acknowledged_two"]) player = self.acknowledgedTwoSoundPlayer;
			[self.openEarsController suspendListening];
			[player play];
		}
		
		if (error) return;
		
		NSString *status = returnDictionary[@"status"];
		NSString *message = nil;
		if ([[returnDictionary allKeys] containsObject:@"message"]) message = returnDictionary[@"message"];
		
		self.statusLabel.text = [status capitalizedString];
		self.messageLabel.text = message;
		
		if (message) {
			speechString = message;
		}
		else {
			speechString = status;
		}
		
		if (speechString) {
			NSTimeInterval delay = 0;
			if (player.playing) delay = player.duration - player.currentTime;
			[self.speechSynthesizer performSelector:@selector(startSpeakingString:) withObject:speechString afterDelay:delay];
			self.messageLabel.text = speechString;
		}
		
		if ([text isEqualToString:@"UPDATE LIST OF PROGRAMS"]) {
			NSMutableArray *languageArray = [NSMutableArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Vocabulary" ofType:@"plist"]];
			[languageArray removeObject:@"SAFARI"];
			[languageArray addObjectsFromArray:returnDictionary[@"list"]];
			
			NSMutableString *programName = [NSMutableString stringWithString:@"<programName> = "];
			[returnDictionary[@"list"] enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
				[programName appendString:obj];
				if (idx != [returnDictionary[@"list"] count] -1) [programName appendString:@" | "];
			}];
			[programName appendString:@";"];
			
			NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
			NSString *documentsDirectory = [paths objectAtIndex:0];
			NSString *path = [documentsDirectory stringByAppendingPathComponent:@"vocabulary.gram"];
			
			NSMutableString *JSGFGrammar = [NSMutableString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"vocabulary" ofType:@"gram"] encoding:NSUTF8StringEncoding error:&error];
			[JSGFGrammar replaceOccurrencesOfString:@"<programName> = SAFARI;" withString:programName options:0 range:NSMakeRange(0, [JSGFGrammar length])];
			[JSGFGrammar writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
			NSLog(@"%@", error);

			[self.openEarsController loadVocabularyList:languageArray withGrammar:path];
			[self.openEarsController updateLanguageModel];
		}
	}];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
	[self.openEarsController resumeListening];
}

- (void)openEarsControllerDidTimeout:(OpenEarsController *)controller {
	NSLog(@"OpenEars controller did timeout.");
	[self.activationState setOn:NO animated:YES];
}

- (void)viewDidUnload {
	[self setTimeLabel:nil];
	[self setStatusLabel:nil];
	[self setMessageLabel:nil];
	[self setActivationState:nil];
	[self setSaidLabel:nil];
	[self setMpb47:nil];
	[self setMpb42:nil];
	[super viewDidUnload];
}

- (IBAction)mpb42pressed:(id)sender {
	[self.acknowledgedSoundPlayer play];
//	NSLog(@"%@", audioPlayer);
}
BOOL asdf = FALSE;
- (IBAction)mpb47pressed:(id)sender {
	[self.acknowledgedTwoSoundPlayer play];
}

@end
