#import <AVFAudio/AVFAudio.h>

static BOOL CustomYTMuteEnabled = NO;

static void CustomYTToggleMute(void) {
    AVAudioSession *session = [AVAudioSession sharedInstance];

    NSError *error = nil;
    BOOL newState = !CustomYTMuteEnabled;

    if (![session setOutputMuted:newState error:&error]) {
        NSLog(@"[CustomYT] Failed to toggle mute: %@", error);
        return;
    }

    CustomYTMuteEnabled = newState;

    NSLog(@"[CustomYT] Mute: %@", newState ? @"ON" : @"OFF");
}
