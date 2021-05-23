#import "Reverie.h"

static void reverieSleepFromPrefs() {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"reveriePrefsNoti" object:nil]; // send notification when prefs button activated
}

static CommonProduct *currentProduct;

%hook SpringBoard
- (void) applicationDidFinishLaunching: (id) arg1 {
	%orig;
	// if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/crux"] || ![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/Reverie"]) add an alert here saying to reinstall Reverie
	[[UIDevice currentDevice] setBatteryMonitoringEnabled: 1]; // make ios monitor the battery
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getCurrentBattery) name:UIDeviceBatteryLevelDidChangeNotification object:nil]; // add observer for battery level
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reverieSleep) name:@"reveriePrefsNoti" object:nil]; // add observer for prefs and cc sleep button
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reverieWake) name:@"reverieWakeNoti" object:nil]; // add observer for hardware wake
}

%new
- (void) reverieSleep {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"reverieOLEDNoti" object:nil]; // make the oled window in root scene
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
	[task launch]; // have a nice dream - ᴀɴɢᴇ ʙᴇᴀᴛʀɪᴄᴇ
	isSleeping = 1;
}

%new
- (void) reverieWake {
	isSleeping = 0;
	[[UIDevice currentDevice] setProximityMonitoringEnabled:1]; // enable proximity sensor
	[[%c(SBAirplaneModeController) sharedInstance] setInAirplaneMode:0]; // disable airplane mode
	[[%c(_CDBatterySaver) sharedInstance] setPowerMode:0 error:nil]; // disable lpm
	[[%c(SBLockScreenManager) sharedInstance] setBiometricAutoUnlockingDisabled:0 forReason:@"ai.paisseon.reverie"]; // enable biometrics
	if (underclock) [currentProduct putDeviceInThermalSimulationMode:@"off"]; // disable cpu throttling

	NSTask* task = [[NSTask alloc] init];
	[task setLaunchPath:@"/usr/bin/killall"]; // respring and kill reverie sleep bin
	[task setArguments:[NSArray arrayWithObjects:@"backboardd", nil]];
	[task launch];
}

%new
- (float) getCurrentBattery {
	currentBattery = [[UIDevice currentDevice] batteryLevel]; // get the current battery percent
	if (currentBattery == sleepPercent && !isSleeping) [self reverieSleep]; // when battery is 7% and not is sleeping
	else if (currentBattery == wakePercent && isSleeping) [self reverieWake]; // when battery is 20% and is sleeping
	return currentBattery;
}
%end

%hook UIRootSceneWindow
static UIView* reverieView; // thanks u/runtimeoverflow!
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
	[reverieView setUserInteractionEnabled:0]; // prevent user interaction 
	[reverieView addSubview:reverieLogo]; // add logo
	[reverieLogo setFrame:CGRectMake(0,0,50,50)]; // 50x50 frame
	[reverieLogo setCenter:rootCentre]; // centre logo on the screen
	[self bringSubviewToFront:reverieView];
	[reverieView bringSubviewToFront:reverieLogo];
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
	if (isSleeping && !viewonpower) return;
	%orig;
}

- (void) _performSleep { // disable sleep button
	if (isSleeping && !viewonpower) return;
	%orig;
}
%end

%hook SBLockHardwareButtonActions

- (bool) disallowsSinglePressForReason: (id*) arg1 { // disable sleep button
	if (isSleeping && !viewonpower) return 1;
	return %orig;
}

- (bool) disallowsDoublePressForReason: (id*) arg1 { // disable sleep button
	if (isSleeping && !viewonpower) return 1;
	return %orig;
}

- (bool) disallowsTriplePressForReason: (id*)arg1 { // disable sleep button
	if (isSleeping && !viewonpower) return 1;
	return %orig;
}

- (bool) disallowsLongPressForReason: (id*) arg1 { // disable sleep button
	if (isSleeping && !viewonpower) return 1;
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
	if (isSleeping && !viewonpower) return;
	%orig;
}
%end

%ctor { // prefs stuff
    preferences = [[HBPreferences alloc] initWithIdentifier:@"ai.paisseon.reverie"];

    [preferences registerBool:&enabled default:YES forKey:@"Enabled"];
    [preferences registerBool:&underclock default:YES forKey:@"Underclock"];
    [preferences registerBool:&viewonpower default:NO forKey:@"ViewOnPower"];
    //[preferences registerObject:&wakePercent default:@".2" forKey:@"WakePercent"]; fuck gcc, this worked in echidna
    //[preferences registerObject:&sleepPercent default:@".05" forKey:@"SleepPercent"];

    if (enabled) {
    	%init;
    	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reverieSleepFromPrefs, (CFStringRef)@"ai.paisseon.reverie/PrefsSleep", NULL, (CFNotificationSuspensionBehavior)kNilOptions);
    }
}