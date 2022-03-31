#include <dispatch/dispatch.h>
#include <mach/mach.h>
#include <objc/runtime.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/pwr_mgt/IOPMLib.h>
#include <UIKit/UIKit.h>

@interface _CDBatterySaver : NSObject
+ (id) sharedInstance;
- (bool) setPowerMode: (long long) arg0 error: (NSString *) arg1;
@end

@interface _UIBatteryView : UIView
@property (nonatomic, assign, readwrite) NSInteger chargingState;
- (void) setChargePercent: (double) arg0;
@end

@interface SBAirplaneModeController : NSObject
+ (id) sharedInstance;
- (void) setInAirplaneMode: (bool) arg0;
@end

@interface SBBacklightController : NSObject
- (void) turnOnScreenFullyWithBacklightSource: (long long) arg0;
@end

@interface SBLockScreenManager : NSObject
+ (id) sharedInstance;
- (void) setBiometricAutoUnlockingDisabled: (bool) arg0 forReason: (NSString *) arg1;
- (bool) isUILocked;
@end

@interface SBMediaController : NSObject
+ (id) sharedInstance;
- (bool) togglePlayPauseForEventSource: (long long) arg0;
- (bool) isPlaying;
@end

@interface SBVolumeControl : NSObject
- (void) increaseVolume;
@end

@interface SpringBoard : UIApplication
+ (id) sharedApplication;
- (void) _simulateLockButtonPress;
@end

@interface UIRootSceneWindow : UIWindow
- (id) initWithDisplayConfiguration: (id) arg0;
- (void) reverie_handleExternalNotification;
@end

void hibernate() {
	SBLockScreenManager *SBLSM      = [objc_getClass("SBLockScreenManager") sharedInstance];
	SBAirplaneModeController *SBAMC = [objc_getClass("SBAirplaneModeController") sharedInstance];
	_CDBatterySaver *_CDBS          = [objc_getClass("_CDBatterySaver") sharedInstance];
	SBMediaController *SBMC         = [objc_getClass("SBMediaController") sharedInstance];
	SpringBoard *SB                 = [objc_getClass("SpringBoard") sharedApplication];
	
	[SBLSM setBiometricAutoUnlockingDisabled: true forReason: @"What, I need a reason for everything?"];
	[SBAMC setInAirplaneMode: true];
	[_CDBS setPowerMode: 1 error: nil];
	
	mach_port_t port     = (mach_port_t)MACH_PORT_NULL;
	kern_return_t ret    = KERN_SUCCESS;
	io_service_t service = (io_service_t)0;
	  
	service              = IOPMFindPowerManagement(port);
	ret                  = IOPMSleepSystem(service);
	
	if (ret == KERN_FAILURE) return;
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		if ([SBMC isPlaying]) [SBMC togglePlayPauseForEventSource: 0];
		if (![SBLSM isUILocked]) [SB _simulateLockButtonPress];
	});
}

void soft_hibernate() {
	SBLockScreenManager *SBLSM      = [objc_getClass("SBLockScreenManager") sharedInstance];
	SBAirplaneModeController *SBAMC = [objc_getClass("SBAirplaneModeController") sharedInstance];
	_CDBatterySaver *_CDBS          = [objc_getClass("_CDBatterySaver") sharedInstance];
	SpringBoard *SB                 = [objc_getClass("SpringBoard") sharedApplication];
	
	[SBLSM setBiometricAutoUnlockingDisabled: true forReason: @"Bruh who tf is this blue-haired chick everyone keeps posting on r/Re_Zero"];
	[SBAMC setInAirplaneMode: true];
	[_CDBS setPowerMode: 1 error: nil];
	if (![SBLSM isUILocked]) [SB _simulateLockButtonPress];
}

void dehibernate() {
	SBLockScreenManager *SBLSM      = [objc_getClass("SBLockScreenManager") sharedInstance];
	SBAirplaneModeController *SBAMC = [objc_getClass("SBAirplaneModeController") sharedInstance];
	_CDBatterySaver *_CDBS          = [objc_getClass("_CDBatterySaver") sharedInstance];
	SpringBoard *SB                 = [objc_getClass("SpringBoard") sharedApplication];
	
	[SBLSM setBiometricAutoUnlockingDisabled: false forReason: @"Слава освободителям"];
	[SBAMC setInAirplaneMode: false];
	[_CDBS setPowerMode: 0 error: nil];
	if ([SBLSM isUILocked]) [SB _simulateLockButtonPress];
}