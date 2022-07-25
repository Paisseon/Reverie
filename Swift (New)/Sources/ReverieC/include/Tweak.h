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
- (bool) isCharging;
- (void) setPercentCharge: (long long) arg0;
@end

@interface SBAirplaneModeController : NSObject
+ (id) sharedInstance;
- (void) setInAirplaneMode: (bool) arg0;
@end

@interface SBBacklightController: NSObject
+ (id) sharedInstance;
- (void) turnOnScreenFullyWithBacklightSource: (long long) arg0;
- (void) _startFadeOutAnimationFromLockSource: (int) arg0;
@end

@interface SBMediaController: NSObject
+ (id) sharedInstance;
- (bool) togglePlayPauseForEventSource: (long long) arg0;
- (bool) isPlaying;
@end

@interface SBVolumeControl: NSObject
- (void) increaseVolume;
- (void) decreaseVolume;
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
