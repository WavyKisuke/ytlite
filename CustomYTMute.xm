#import <AVFAudio/AVFAudio.h>

static BOOL CustomYTMuteEnabled = NO;

// Hook AVAudioSession's category setters so every setCategory call from
// YouTube (or AVPlayer) is forced to ambient + mixWithOthers. This keeps
// YouTube from activating a playback-mode session that would silence
// other apps' audio when we mute YouTube's output.
%hook AVAudioSession

- (BOOL)setCategory:(NSString *)category error:(NSError **)outError {
    return %orig(AVAudioSessionCategoryAmbient, outError);
}

- (BOOL)setCategory:(NSString *)category
         withOptions:(AVAudioSessionCategoryOptions)options
               error:(NSError **)outError {
    return %orig(AVAudioSessionCategoryAmbient,
                 AVAudioSessionCategoryOptionMixWithOthers,
                 outError);
}

%end

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
