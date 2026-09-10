#import <AVFAudio/AVFAudio.h>
#import <objc/runtime.h>

static BOOL CustomYTMuteEnabled = NO;

// Saved original IMPs. Captured once at dylib load time so the swizzled
// implementations can call through without recursing into themselves.
static BOOL (*CustomYT_originalSetCategoryWithOptions)(id, SEL, NSString *, AVAudioSessionCategoryOptions, NSError **);
static BOOL (*CustomYT_originalSetCategory)(id, SEL, NSString *, NSError **);

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

// Swizzled: ignore the requested category/options and always use
// ambient + mixWithOthers so YouTube (or AVPlayer) can't switch the
// session back to a playback-mode category that silences other apps.
static BOOL CustomYT_swizzledSetCategoryWithOptions(id self, SEL _cmd, NSString *category, AVAudioSessionCategoryOptions options, NSError **outError) {
    return CustomYT_originalSetCategoryWithOptions(self, _cmd,
        AVAudioSessionCategoryAmbient,
        AVAudioSessionCategoryOptionMixWithOthers,
        outError);
}

static BOOL CustomYT_swizzledSetCategory(id self, SEL _cmd, NSString *category, NSError **outError) {
    return CustomYT_originalSetCategory(self, _cmd, AVAudioSessionCategoryAmbient, outError);
}

__attribute__((constructor)) static void CustomYTInit(void) {
    Class cls = [AVAudioSession class];

    Method m3 = class_getInstanceMethod(cls, @selector(setCategory:withOptions:error:));
    if (m3) {
        CustomYT_originalSetCategoryWithOptions =
            (BOOL (*)(id, SEL, NSString *, AVAudioSessionCategoryOptions, NSError **))method_getImplementation(m3);
        method_setImplementation(m3, (IMP)CustomYT_swizzledSetCategoryWithOptions);
    }

    Method m2 = class_getInstanceMethod(cls, @selector(setCategory:error:));
    if (m2) {
        CustomYT_originalSetCategory =
            (BOOL (*)(id, SEL, NSString *, NSError **))method_getImplementation(m2);
        method_setImplementation(m2, (IMP)CustomYT_swizzledSetCategory);
    }
}
