//
//  ViewController.h
//  Computer Satellite
//
//  Created by E-Liang Tan on 18/8/12.
//  Copyright (c) 2012 E-Liang Tan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "VSSpeechSynthesizer.h"
#import "OpenEarsController.h"
#import <OpenEars/FliteController.h>

@interface ViewController : UIViewController <AVAudioPlayerDelegate, VSSpeechSynthesizerDelegate, OpenEarsControllerDelegate>

@property (nonatomic, strong) VSSpeechSynthesizer *speechSynthesizer;
@property (nonatomic, strong) OpenEarsController *openEarsController;
@property (nonatomic, strong) FliteController *flite;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

@property (nonatomic, strong) AVAudioPlayer *errorSoundPlayer;
@property (nonatomic, strong) AVAudioPlayer *activatedSoundPlayer;
@property (nonatomic, strong) AVAudioPlayer *acknowledgedSoundPlayer;
@property (nonatomic, strong) AVAudioPlayer *acknowledgedTwoSoundPlayer;

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *saidLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UISwitch *activationState;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *mpb42;
- (IBAction)mpb42pressed:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *mpb47;
- (IBAction)mpb47pressed:(id)sender;


@end
