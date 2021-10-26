#import "Reverie.h"

static void refreshPrefs() { // using a modified version of skittyprefs
	CFArrayRef keyList = CFPreferencesCopyKeyList((CFStringRef)bundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if (keyList) {
		settings = (NSMutableDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, (CFStringRef)bundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
		CFRelease(keyList);
	} else settings = nil;
	if (!settings) settings = [[NSMutableDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"/var/mobile/Library/Preferences/%@.plist", bundleIdentifier]];

	enabled           = [([settings objectForKey:@"enabled"] ?: @(true)) boolValue];
	throttleCPU       = [([settings objectForKey:@"throttleCPU"] ?: @(false)) boolValue];
	hibernateOnCharge = [([settings objectForKey:@"hibernateOnCharge"] ?: @(false)) boolValue];
	viewOnPower       = [([settings objectForKey:@"viewOnPower"] ?: @(false)) boolValue];
	sleepPercent      = [([settings objectForKey:@"sleepPercent"] ?: @(7)) integerValue];
	wakePercent       = [([settings objectForKey:@"wakePercent"] ?: @(20)) integerValue];
}

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	refreshPrefs();
}

static void reverieSleepFromPrefs() {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"reverieSleepNoti" object:nil]; // send notification when prefs button activated
}

static CommonProduct *currentProduct;

%hook SpringBoard
- (void) applicationDidFinishLaunching: (id) arg1 {
	%orig;
	[[UIDevice currentDevice] setBatteryMonitoringEnabled:true]; // make ios monitor the battery
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getCurrentBattery) name:UIDeviceBatteryLevelDidChangeNotification object:nil]; // add observer for battery level
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reverieSleep) name:@"reverieSleepNoti" object:nil]; // add observer for prefs and cc sleep button
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reverieWake) name:@"reverieWakeNoti" object:nil]; // add observer for hardware wake
}

%new
- (void) reverieSleep {
	if ([[UIDevice currentDevice] batteryState] == UIDeviceBatteryStateCharging && !hibernateOnCharge) return; // if device is charging and user opts out fast charge don't sleep
	if (viewOnPower)[[NSNotificationCenter defaultCenter] postNotificationName:@"reverieOLEDNoti" object:nil]; // make the oled window in root scene
	[[UIDevice currentDevice] setProximityMonitoringEnabled:false]; // disable proximity sensor
	[[%c(SBAirplaneModeController) sharedInstance] setInAirplaneMode:true]; // enable airplane mode
	[[%c(_CDBatterySaver) sharedInstance] setPowerMode:1 error:nil]; // enable lpm
	[[%c(SBLockScreenManager) sharedInstance] setBiometricAutoUnlockingDisabled:true forReason:@"ai.paisseon.reverie"]; // disable automatic biometric unlock
	if (throttleCPU) [currentProduct putDeviceInThermalSimulationMode:@"heavy"]; // enable cpu throttling
	io_connect_t port = IOPMFindPowerManagement((mach_port_t)MACH_PORT_NULL); // get the power manager for MACH_PORT_NULL
	IOPMSleepSystem(port); // have a nice dream
	IOServiceClose(port); // close the mach port after we're done
	[self _simulateLockButtonPress]; // lock device
	isSleeping = true;
}

%new
- (void) reverieWake {
	isSleeping = false;
	[[UIDevice currentDevice] setProximityMonitoringEnabled:true]; // enable proximity sensor
	[[%c(SBAirplaneModeController) sharedInstance] setInAirplaneMode:false]; // disable airplane mode
	[[%c(_CDBatterySaver) sharedInstance] setPowerMode:0 error:nil]; // disable lpm
	[[%c(SBLockScreenManager) sharedInstance] setBiometricAutoUnlockingDisabled:false forReason:@"ai.paisseon.reverie"]; // enable biometrics
	if (throttleCPU) [currentProduct putDeviceInThermalSimulationMode:@"off"]; // disable cpu throttling

	pid_t pid;
	const char *args[] = {"sbreload", NULL, NULL, NULL};
	posix_spawn(&pid, "usr/bin/sbreload", NULL, NULL, (char *const *)args, NULL); // respring to disable hibernation
}

%new
- (CGFloat) getCurrentBattery {
	origBattery = [[UIDevice currentDevice] batteryLevel] * 100; // store original cgfloat to avoid issues
	currentBattery = (int)origBattery; // cast the current battery percent as integer
	if (!isSleeping && currentBattery == sleepPercent) [self reverieSleep]; // sleep when at user's sleep percent
	if (isSleeping && currentBattery == wakePercent) [self reverieWake]; // wake when at user's wake percent
	return origBattery;
}
%end

%hook UIRootSceneWindow
static UIView* reverieView;
static UIImageView* reverieLogo;

- (id) initWithDisplayConfiguration: (id) arg1 {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reverieOLED) name:@"reverieOLEDNoti" object:nil]; // add observer for oled notification
	return %orig;
}

%new
- (void) reverieOLED {
	CGPoint rootCentre = self.center; // centre of the screen
	reverieView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]]; // init view
	reverieLogo = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"moon.zzz.fill"]]; // get the moon logo from sf symbol
	[self addSubview:reverieView];
	
	[reverieView setBackgroundColor:[UIColor blackColor]]; // back in black
	[reverieView setUserInteractionEnabled:false]; // prevent user interaction 
	[reverieView addSubview:reverieLogo]; // add logo
	[reverieLogo setFrame:CGRectMake(0,0,50,50)]; // 50x50 frame
	[reverieLogo setCenter:rootCentre]; // centre logo on the screen
	[self bringSubviewToFront:reverieView]; // bring the black screen to the front
	[reverieView bringSubviewToFront:reverieLogo]; // and show the logo on top of it (this is only visible element except black)
}
%end

%hook SBVolumeControl // thanks to Litten 
- (void) increaseVolume {
	if (!isSleeping) {
		%orig;
		return;
	}

	timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(resetPresses) userInfo:nil repeats:NO];

	if (!timer) return;
	wakePresses++;
	if (wakePresses == 3)
		[[NSNotificationCenter defaultCenter] postNotificationName:@"reverieWakeNoti" object:nil];
}

%new
- (void)resetPresses { // reset presses after timer is up
	wakePresses = 0;
	[timer invalidate];
	timer = nil;
}
%end

%hook CommonProduct // thanks to Ryan Petrich
- (id) initProduct: (id) data {
	if (enabled && ((self = %orig()))) if ([self respondsToSelector:@selector(putDeviceInThermalSimulationMode:)]) currentProduct = self;
	return self;
}

- (void) dealloc {
	if (currentProduct == self) currentProduct = nil;
	%orig();
}
%end

// begin code to disable unwanted waking from hardware

%hook SBTapToWakeController
- (void) tapToWakeDidRecognize: (id) arg1 {
	if (isSleeping) return;
	%orig;
}
%end

%hook SBLiftToWakeController
- (void) wakeGestureManager: (id) arg1 didUpdateWakeGesture: (long long) arg2 orientation: (int) arg3 {
	if (isSleeping) return;
	%orig;
}
%end

%hook SBSleepWakeHardwareButtonInteraction
- (void )_performWake {
	if (isSleeping && !viewOnPower) return;
	%orig;
}

- (void) _performSleep {
	if (isSleeping && !viewOnPower) return;
	%orig;
}
%end

%hook SBLockHardwareButtonActions
- (bool) disallowsSinglePressForReason: (id*) arg1 {
	if (isSleeping && !viewOnPower) return true;
	return %orig;
}

- (bool) disallowsLongPressForReason: (id*) arg1 {
	if (isSleeping && !viewOnPower) return true;
	return %orig;
}
%end

%hook SBHomeHardwareButton
- (void) initialButtonDown: (id) arg1 {
	if (isSleeping) return;
	%orig;
}

- (void) singlePressUp: (id) arg1 {
	if (isSleeping) return;
	%orig;
}
%end

%hook SBHomeHardwareButtonActions
- (void) performLongPressActions {
	if (isSleeping) return;
	%orig;
}
%end

%hook SBBacklightController
- (void) turnOnScreenFullyWithBacklightSource: (long long) arg1 {
	if (isSleeping && !viewOnPower) return;
	%orig;
}
%end

// end code to disable unwanted waking from hardware

%ctor { // prefs stuff
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback) PreferencesChangedCallback, (CFStringRef)[NSString stringWithFormat:@"%@.prefschanged", bundleIdentifier], NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	refreshPrefs();

	if (enabled) {
		%init;
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reverieSleepFromPrefs, (CFStringRef)@"reverieExternalNoti", NULL, (CFNotificationSuspensionBehavior)kNilOptions);
	}
}