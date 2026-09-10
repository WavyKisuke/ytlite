#import <AVFAudio/AVFAudio.h>
#import <objc/runtime.h>

static BOOL CustomYTMuteEnabled = NO;

static void CustomYTToggleMute(void) {
    AVAudioSession *session = [AVAudioSession sharedInstance];

    NSError *error = nil;
    BOOL newState = !CustomYTMuteEnabled;

    // Use ambient + mixWithOthers so YouTube's session respects system audio
    // instead of activating in `playback` mode and silencing other apps.
    if (![session setCategory:AVAudioSessionCategoryAmbient
                  withOptions:AVAudioSessionCategoryOptionMixWithOthers
                        error:&error]) {
        NSLog(@"[CustomYT] Failed to set audio session category: %@", error);
        return;
    }

    if (![session setOutputMuted:newState error:&error]) {
        NSLog(@"[CustomYT] Failed to toggle mute: %@", error);
        return;
    }

    CustomYTMuteEnabled = newState;

    NSLog(@"[CustomYT] Mute: %@", newState ? @"ON" : @"OFF");
}

// Force every setCategory:withOptions:error: call to use ambient + mixWithOthers.
// YouTube's own code (and any third-party player code) may try to switch the
// session back to `playback` after the toggle above runs; this swizzle makes
// sure it sticks so muting YouTube never takes over the system audio.
static BOOL CustomYT_swizzledSetCategoryWithOptions(id self, SEL _cmd, NSString *category, AVAudioSessionCategoryOptions options, NSError **outError) {
    Method method = class_getInstanceMethod([self class], _cmd);
    BOOL (*original)(id, SEL, NSString *, AVAudioSessionCategoryOptions, NSError **) =
        (BOOL (*)(id, SEL, NSString *, AVAudioSessionCategoryOptions, NSError **))method_getImplementation(method);
    return original(self, _cmd, AVAudioSessionCategoryAmbient, AVAudioSessionCategoryOptionMixWithOthers, outError);
}

__attribute__((constructor)) static void CustomYTInit(void) {
    Method method = class_getInstanceMethod([AVAudioSession class], @selector(setCategory:withOptions:error:));
    method_setImplementation(method, (IMP)CustomYT_swizzledSetCategoryWithOptions);
}
