#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <Cephei/HBPreferences.h>

HBPreferences *preferences;

bool enabled = 1;
bool underclock= 1;
bool isSleeping = 0;
float currentBattery;
float sleepPercent = 0.05;
float wakePercent = 0.2;
int wakePresses = 0;
NSTimer* timer = nil;
UIImageView* reverieLogo;
UIView* reverieView;

@interface SpringBoard : UIApplication
- (void) _simulateLockButtonPress;
@end

@interface SBHomeScreenWindow : UIView
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

@interface SBHomeScreenViewController : UIViewController
- (float) getCurrentBattery;
- (void) reverieSleep;
- (void) reverieWake;
@end