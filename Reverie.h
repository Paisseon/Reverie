#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

static NSString* bundleIdentifier = @"ai.paisseon.reverie";
static NSMutableDictionary *settings;

static bool enabled;
static bool throttleCPU;
static bool viewOnPower;
static int sleepPercent;
static int wakePercent;

bool isSleeping = 0;
int currentBattery;
int wakePresses = 0;
CGFloat origBattery;
NSTimer* timer = nil;

@interface SpringBoard : UIApplication
- (void) _simulateLockButtonPress;
- (CGFloat) getCurrentBattery;
- (void) reverieSleep;
- (void) reverieWake;
@end

@interface UIRootSceneWindow : UIWindow
- (void) reverieOLED;
@end

@interface SBVolumeControl : NSObject
- (void) increaseVolume;
- (void) resetPresses;
@end

@interface SBLockScreenManager : NSObject
+ (id) sharedInstance;
- (void) setBiometricAutoUnlockingDisabled: (bool) arg1 forReason: (id) arg2;
@end

@interface SBAirplaneModeController : NSObject
+ (id )sharedInstance;
- (void) setInAirplaneMode: (BOOL) arg1;
@end

@interface _CDBatterySaver : NSObject
+ (id) sharedInstance;
- (BOOL) setPowerMode: (long long) arg1 error: (id *) arg2;
@end

@interface NSTask : NSObject
@property (copy) NSArray* arguments;
@property (copy) NSString* launchPath;
- (void) launch;
@end

@interface CommonProduct : NSObject
- (void) putDeviceInThermalSimulationMode: (NSString *) simulationMode;
@end