#import "Reverie.h"

static void reverieSleepFromPrefs() {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"reveriePrefsNoti" object:nil]; // send notification when prefs button activated
}

static CommonProduct *currentProduct;

%hook SBHomeScreenViewController
- (void) viewDidLoad {
	isSleeping = 0;
	// TODO: check to make sure all necessary files exist /usr/bin/crux and /usr/bin/Reverie
	[[UIDevice currentDevice] setBatteryMonitoringEnabled: 1]; // make ios monitor the battery
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getCurrentBattery) name:UIDeviceBatteryLevelDidChangeNotification object:nil]; // add observer for battery level
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reverieSleep) name:@"reveriePrefsNoti" object:nil]; // add observer for prefs sleep button
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reverieWake) name:@"reverieWakeNoti" object:nil]; // add observer for hardware wake
	%orig;
}

%new
- (void) reverieSleep {
	isSleeping = 1;
	int screenWidth = [[UIScreen mainScreen] bounds].size.width * 0.5; // positioning is off for some reason
	int screenHeight = [[UIScreen mainScreen] bounds].size.height * 0.5; // but does it really matter?
	reverieView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds]; // init the window used as a backdrop for logo
	[self.view addSubview:reverieView]; // add the subview to vc
	reverieLogo = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"/Library/Application Support/Reverie/logo.png"]]; // get logo from file
	[reverieView setBackgroundColor:[UIColor blackColor]]; // hey siri play back in black
	[reverieView addSubview:reverieLogo]; // add logo
	[reverieLogo setCenter:CGPointMake(screenHeight, screenWidth)]; // move it out of the corner
	[[UIDevice currentDevice] setProximityMonitoringEnabled:0]; // disable proximity sensor
	[[%c(SBAirplaneModeController) sharedInstance] setInAirplaneMode:1]; // enable airplane mode
	[[%c(_CDBatterySaver) sharedInstance] setPowerMode:1 error:nil]; // enable lpm
	[[%c(SBLockScreenManager) sharedInstance] setBiometricAutoUnlockingDisabled:1 forReason:@"ai.paisseon.reverie"]; // disable automatic biometric unlock
	if (underclock) [currentProduct putDeviceInThermalSimulationMode:@"heavy"]; // enable cpu throttling
	SpringBoard* sb = (SpringBoard *)[objc_getClass("SpringBoard") sharedApplication]; // get sb class
	[sb _simulateLockButtonPress]; // lock device
	NSTask* task = [[NSTask alloc] init];
	[task setLaunchPath:@"/usr/bin/crux"]; // if not root reverie bin doesn't work
	[task setArguments:[NSArray arrayWithObjects:@"/usr/bin/Reverie", nil]]; // this is reverie.c
	[task launch]; // have a nice dream. see you in hell. - ushiromiya ange
	sleep(3);
}

%new
- (void) reverieWake {
	[[UIDevice currentDevice] setProximityMonitoringEnabled:1]; // enable proximity sensor
	[[%c(SBAirplaneModeController) sharedInstance] setInAirplaneMode:0]; // disable airplane mode
	[[%c(_CDBatterySaver) sharedInstance] setPowerMode:0 error:nil]; // disable lpm
	[[%c(SBLockScreenManager) sharedInstance] setBiometricAutoUnlockingDisabled:0 forReason:@"ai.paisseon.reverie"]; // enable biometrics
	if (underclock) [currentProduct putDeviceInThermalSimulationMode:@"off"]; // actually disable cpu throttling

	NSTask* task = [[NSTask alloc] init];
	[task setLaunchPath:@"/usr/bin/killall"]; // respring and kill reverie sleep bin
	[task setArguments:[NSArray arrayWithObjects:@"backboardd", nil]];
	[task launch];
}

%new
- (float) getCurrentBattery {
	currentBattery = [[UIDevice currentDevice] batteryLevel]; // get the current battery percent
	if (currentBattery == sleepPercent && !isSleeping) [self reverieSleep]; // when battery is 5% and not is sleeping
	else if (currentBattery == wakePercent && isSleeping) [self reverieWake]; // when battery is 20% and is sleeping
	return currentBattery;
}
%end

%hook SBVolumeControl // from puck by litten
- (void) increaseVolume {
	if (!isSleeping) {
		%orig;
		return;
	}

	timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(resetPresses) userInfo:nil repeats:NO];

	if (!timer) return;
	wakePresses++;
	if (wakePresses >= 3)
		[[NSNotificationCenter defaultCenter] postNotificationName:@"reverieWakeNoti" object:nil];
}

%new
- (void)resetPresses { // reset presses after timer is up
	wakePresses = 0;
	[timer invalidate];
	timer = nil;
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
	if (isSleeping) return;
	%orig;
}

- (void) _performSleep { // disable sleep button
	if (isSleeping) return;
	%orig;
}
%end

%hook SBLockHardwareButtonActions

- (bool) disallowsSinglePressForReason: (id*) arg1 { // disable sleep button
	if (isSleeping) return 1;
	return %orig;
}

- (bool) disallowsDoublePressForReason: (id*) arg1 { // disable sleep button
	if (isSleeping) return 1;
	return %orig;
}

- (bool) disallowsTriplePressForReason: (id*)arg1 { // disable sleep button
	if (isSleeping) return 1;
	return %orig;
}

- (bool) disallowsLongPressForReason: (id*) arg1 { // disable sleep button
	if (isSleeping) return 1;
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
	if (isSleeping) return;
	%orig;
}
%end

%hook CommonProduct // from powercuff by ryan petrich
- (id) initProduct: (id) data {
	if (enabled && (self = %orig())) if ([self respondsToSelector:@selector(putDeviceInThermalSimulationMode:)]) currentProduct = self;
	return self;
}

- (void) dealloc {
	if (currentProduct == self) currentProduct = nil;
	%orig();
}
%end

%ctor { // prefs stuff
    preferences = [[HBPreferences alloc] initWithIdentifier:@"ai.paisseon.reverie"];

    [preferences registerBool:&enabled default:YES forKey:@"Enabled"];
    [preferences registerBool:&underclock default:YES forKey:@"Underclock"];
    //[preferences registerObject:&wakePercent default:@".2" forKey:@"WakePercent"]; fuck gcc, this worked in echidna
    //[preferences registerObject:&sleepPercent default:@".05" forKey:@"SleepPercent"];

    if (enabled) {
    	%init;
    	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reverieSleepFromPrefs, (CFStringRef)@"ai.paisseon.reverie/PrefsSleep", NULL, (CFNotificationSuspensionBehavior)kNilOptions);
    }
}