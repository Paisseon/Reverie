#import "Reverie.h"

static void refreshPrefs() { // using a modified version of skittyprefs
    CFArrayRef keyList = CFPreferencesCopyKeyList((CFStringRef)bundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if (keyList) {
        settings = (NSMutableDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, (CFStringRef)bundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
        CFRelease(keyList);
    } else settings = nil;
    if (!settings) settings = [[NSMutableDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"/var/mobile/Library/Preferences/%@.plist", bundleIdentifier]];

    enabled = [([settings objectForKey:@"enabled"] ?: @(true)) boolValue];
    throttleCPU = [([settings objectForKey:@"throttleCPU"] ?: @(true)) boolValue];
    viewOnPower = [([settings objectForKey:@"viewOnPower"] ?: @(false)) boolValue];
    sleepPercent = [([settings objectForKey:@"sleepPercent"] ?: @(7)) integerValue];
    wakePercent = [([settings objectForKey:@"wakePercent"] ?: @(20)) integerValue];
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
	[[NSNotificationCenter defaultCenter] postNotificationName:@"reverieOLEDNoti" object:nil]; // make the oled window in root scene
	[[UIDevice currentDevice] setProximityMonitoringEnabled:false]; // disable proximity sensor
	[[%c(SBAirplaneModeController) sharedInstance] setInAirplaneMode:true]; // enable airplane mode
	[[%c(_CDBatterySaver) sharedInstance] setPowerMode:1 error:nil]; // enable lpm
	[[%c(SBLockScreenManager) sharedInstance] setBiometricAutoUnlockingDisabled:true forReason:@"ai.paisseon.reverie"]; // disable automatic biometric unlock
	if (throttleCPU) [currentProduct putDeviceInThermalSimulationMode:@"heavy"]; // enable cpu throttling
	SpringBoard* sb = (SpringBoard *)[objc_getClass("SpringBoard") sharedApplication]; // get sb class
	[sb _simulateLockButtonPress]; // lock device

	NSTask* task = [[NSTask alloc] init];
	[task setLaunchPath:@"/usr/bin/cruxx"]; // if not root reverie bin doesn't work... this is crux binary by creaturesurvive-- thanks u/darkxdddd. also fuck mainrepo.
	[task setArguments:[NSArray arrayWithObjects:@"/usr/bin/Reverie", nil]]; // this is reverie.c
	[task launch]; // have a nice dream - ᴀɴɢᴇ ʙᴇᴀᴛʀɪᴄᴇ
	isSleeping = 1;
}

%new
- (void) reverieWake {
	isSleeping = 0;
	[[UIDevice currentDevice] setProximityMonitoringEnabled:true]; // enable proximity sensor
	[[%c(SBAirplaneModeController) sharedInstance] setInAirplaneMode:false]; // disable airplane mode
	[[%c(_CDBatterySaver) sharedInstance] setPowerMode:0 error:nil]; // disable lpm
	[[%c(SBLockScreenManager) sharedInstance] setBiometricAutoUnlockingDisabled:false forReason:@"ai.paisseon.reverie"]; // enable biometrics
	if (throttleCPU) [currentProduct putDeviceInThermalSimulationMode:@"off"]; // disable cpu throttling

	NSTask* task = [[NSTask alloc] init];
	[task setLaunchPath:@"/usr/bin/killall"]; // respring and kill reverie sleep bin
	[task setArguments:[NSArray arrayWithObjects:@"backboardd", nil]];
	[task launch];
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
	CGPoint rootCentre = self.center;
	reverieView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]]; // init view
	reverieLogo = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"/Library/Application Support/Reverie/logo.png"]]; // logo from file

	[self addSubview:reverieView];
	[reverieView setBackgroundColor:[UIColor blackColor]]; // back in black
	[reverieView setUserInteractionEnabled:false]; // prevent user interaction 
	[reverieView addSubview:reverieLogo]; // add logo
	[reverieLogo setFrame:CGRectMake(0,0,50,50)]; // 50x50 frame
	[reverieLogo setCenter:rootCentre]; // centre logo on the screen
	[self bringSubviewToFront:reverieView];
	[reverieView bringSubviewToFront:reverieLogo];
}
%end

%hook SBVolumeControl // thanks litten ^^ 
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

%hook CommonProduct // from powercuff by ryan petrich
- (id) initProduct: (id) data {
	if (enabled && ((self = %orig()))) if ([self respondsToSelector:@selector(putDeviceInThermalSimulationMode:)]) currentProduct = self;
	return self;
}

- (void) dealloc {
	if (currentProduct == self) currentProduct = nil;
	%orig();
}
%end

%hook SBTapToWakeController
- (void) tapToWakeDidRecognize: (id) arg1 { // disable tap to wake
	if (isSleeping) return;
	%orig;
}
%end

%hook SBLiftToWakeController
- (void) wakeGestureManager: (id) arg1 didUpdateWakeGesture: (long long) arg2 orientation: (int) arg3 { // disable raise to wake
	if (isSleeping) return;
	%orig;
}
%end

%hook SBSleepWakeHardwareButtonInteraction
- (void )_performWake { // disable sleep button
	if (isSleeping && !viewOnPower) return;
	%orig;
}

- (void) _performSleep { // disable sleep button
	if (isSleeping && !viewOnPower) return;
	%orig;
}
%end

%hook SBLockHardwareButtonActions

- (bool) disallowsSinglePressForReason: (id*) arg1 { // disable sleep button
	if (isSleeping && !viewOnPower) return 1;
	return %orig;
}

- (bool) disallowsLongPressForReason: (id*) arg1 { // disable sleep button
	if (isSleeping && !viewOnPower) return 1;
	return %orig;
}
%end

%hook SBHomeHardwareButton
- (void) initialButtonDown: (id) arg1 { // disable home button
	if (isSleeping) return;
	%orig;
}

- (void) singlePressUp: (id) arg1 { // disable home button
	if (isSleeping) return;
	%orig;
}
%end

%hook SBHomeHardwareButtonActions
- (void) performLongPressActions { // disable home button
	if (isSleeping) return;
	%orig;
}
%end

%hook SBBacklightController
- (void) turnOnScreenFullyWithBacklightSource: (long long) arg1 { // prevent display from turning on
	if (isSleeping && !viewOnPower) return;
	%orig;
}
%end

%ctor { // prefs stuff
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback) PreferencesChangedCallback, (CFStringRef)[NSString stringWithFormat:@"%@.prefschanged", bundleIdentifier], NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    refreshPrefs();

    if (enabled) {
    	%init;
    	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reverieSleepFromPrefs, (CFStringRef)@"reverieExternalNoti", NULL, (CFNotificationSuspensionBehavior)kNilOptions);
    }
}