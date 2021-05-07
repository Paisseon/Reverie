#import "_Reverie.h"

static void reverieSleepFromPrefs() {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"reveriePrefsNoti" object:nil]; // send notification when prefs button activated
}

static CommonProduct *currentProduct;

%hook SpringBoard
- (void) applicationDidFinishLaunching: (id) arg1 {
	%orig;
	isSleeping = 0;
	// check to make sure all necessary files exist. /usr/bin/crux and /usr/bin/Reverie
	[[UIDevice currentDevice] setBatteryMonitoringEnabled: 1]; // make ios monitor the battery
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getCurrentBattery) name:UIDeviceBatteryLevelDidChangeNotification object:nil]; // add observer for battery level
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reverieSleep) name:@"reveriePrefsNoti" object:nil]; // add observer for prefs sleep button
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reverieWake) name:@"reverieWakeNoti" object:nil]; // add observer for hardware wake
}

%new
- (void) reverieSleep {
	[[UIDevice currentDevice] setProximityMonitoringEnabled: 0]; // disable proximity sensor
	[[%c(SBAirplaneModeController) sharedInstance] setInAirplaneMode: 1]; // enable airplane mode
	[[%c(_CDBatterySaver) sharedInstance] setPowerMode:1 error:nil]; // enable lpm
	[currentProduct putDeviceInThermalSimulationMode:@"heavy"]; // enable cpu throttling
	
	SpringBoard* sb = (SpringBoard *)[objc_getClass("SpringBoard") sharedApplication]; // get sb class
	[sb _simulateLockButtonPress]; // lock device
	isSleeping = 1;
	NSTask* task = [[NSTask alloc] init];
	[task setLaunchPath:@"/usr/bin/crux"]; // if not root reverie bin doesn't work
	[task setArguments:[NSArray arrayWithObjects:@"/usr/bin/Reverie", nil]]; // this is reverie.c binary
	[task launch];
	sleep(4); // reverie.c wakes after 3 seconds for whatever reason, this prevents it
}

%new
- (void) reverieWake {
	[[UIDevice currentDevice] setProximityMonitoringEnabled: 1]; // enable proximity sensor
	[[%c(SBAirplaneModeController) sharedInstance] setInAirplaneMode: 0]; // disable airplane mode
	[[%c(_CDBatterySaver) sharedInstance] setPowerMode:0 error:nil]; // disable lpm
	[currentProduct putDeviceInThermalSimulationMode:@"off"]; // disable cpu throttling

	NSTask* task = [[NSTask alloc] init];
	[task setLaunchPath:@"/usr/bin/killall"]; // respring and kill reverie sleep bin
	[task setArguments:[NSArray arrayWithObjects:@"backboardd", nil]];
	[task launch];
	isSleeping = 0;
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

    if (enabled) {
    	%init;
    	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reverieSleepFromPrefs, (CFStringRef)@"ai.paisseon.reverie/PrefsSleep", NULL, (CFNotificationSuspensionBehavior)kNilOptions);
    }
}