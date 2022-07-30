#import <dispatch/dispatch.h>
#import <mach/mach.h>
#import <objc/runtime.h>
#import <IOKit/pwr_mgt/IOPMLib.h>
#import <IOKit/IOMessage.h>
#import <UIKit/UIKit.h>

@interface _CDBatterySaver: NSObject
+ (id) sharedInstance;
- (bool) setPowerMode: (long long) arg0 error: (NSString *) arg1;
- (long long) getPowerMode;
@end

@interface BCBatteryDevice: NSObject
@property (assign,getter=isCharging,nonatomic) BOOL charging;
- (void) setCharging: (bool) arg0;
- (void) setPercentCharge: (long long) arg0;
@end

@interface SBAirplaneModeController : NSObject
+ (id) sharedInstance;
- (void) setInAirplaneMode: (bool) arg0;
- (bool) isInAirplaneMode;
@end

@interface SBBacklightController: NSObject
+ (id) sharedInstance;
- (void) turnOnScreenFullyWithBacklightSource: (long long) arg0;
- (void) _startFadeOutAnimationFromLockSource: (int) arg0;
@end

@interface SBLockScreenManager: NSObject
+ (id) sharedInstance;
- (bool) isUILocked;
- (bool) unlockUIFromSource: (int) arg0 withOptions: (id) arg1;
- (bool) lockUIFromSource: (int) arg0 withOptions: (id) arg1;
@end

@interface SBMediaController: NSObject
+ (id) sharedInstance;
- (bool) togglePlayPauseForEventSource: (long long) arg0;
- (bool) isPlaying;
@end

// @interface SBVolumeControl: NSObject
// - (void) increaseVolume;
// @end

@interface SBVolumeHardwareButton: NSObject
- (void) volumeIncreasePress: (id) arg0;
@end

@interface SpringBoard: UIApplication
+ (id) sharedApplication;
@end

@interface UIRootSceneWindow: UIWindow
- (id) initWithDisplayConfiguration: (id) arg0;
- (void) reverie_handleExternalNotification;
@end

SBAirplaneModeController *sbamc() {
    return (SBAirplaneModeController *)[objc_getClass("SBAirplaneModeController") sharedInstance];
}

_CDBatterySaver *_cdbs() {
    return (_CDBatterySaver *)[objc_getClass("_CDBatterySaver") sharedInstance];
}

SBBacklightController *sbblc() {
    return (SBBacklightController *)[objc_getClass("SBBacklightController") sharedInstance];
}

SBMediaController *sbmec() {
    return (SBMediaController *)[objc_getClass("SBMediaController") sharedInstance];
}

SBLockScreenManager *sblsm() {
    return (SBLockScreenManager *)[objc_getClass("SBLockScreenManager") sharedInstance];
}