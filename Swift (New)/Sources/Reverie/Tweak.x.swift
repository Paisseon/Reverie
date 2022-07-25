import Orion
import ReverieC
import UIKit

struct Core : HookGroup {}

var isHibernating = false
var recentWake    = false
var didAutoWake   = false
var didAutoSleep  = false
var wakePresses   = 0

var proximity     = false
var charging      = false

let logo          = UIImageView()
let view          = UIView()

var port          = IONotificationPortRef(bitPattern: 0)
var connect       = io_connect_t(0)
var object        = io_object_t(0)

// Handle changes to the IOKit power status

func handlePowerChange(_ arg0: UnsafeMutableRawPointer?, _ arg1: io_service_t, _ arg2: natural_t, _ arg3: UnsafeMutableRawPointer?) {
    if connect != 0 {
        switch arg2 {
            case UInt32(0x280):
                IOAllowPowerChange(connect, Int(arg2))
            case UInt32(0x300):
                IOPMSleepSystem(connect)
            case UInt32(0x320):
                IOCancelPowerChange(connect, Int(arg2))
                IOPMSleepSystem(connect)
            default:
                IOPMSleepSystem(connect)
        }
    }
}

// Enable some battery savers and enter hibernation mode (using IOKit if soft hibernation is disabled)

func hibernate(soft: Bool = false) {
    let airplane  = sbamc()!
    let backlight = sbblc()!
    let battery   = _cdbs()!
    let media     = sbmec()!
    
    proximity     = UIDevice.current.isProximityMonitoringEnabled
    
    UIDevice.current.isProximityMonitoringEnabled = false
    battery.setPowerMode(1, error: nil)
    airplane.setInAirplaneMode(true)
    
    if !soft {
        if media.isPlaying() {
            media.togglePlayPause(forEventSource: 0)
        }
        
        backlight._startFadeOutAnimation(fromLockSource: 0);
        
        connect = IORegisterForSystemPower(nil, &port, handlePowerChange, &object)
        
        if connect != 0 {
            IOPMSleepSystem(connect)
        }
    }
}

// Wake from hibernation status

func dehibernate() {
    let airplane  = sbamc()!
    let backlight = sbblc()!
    let battery   = _cdbs()!
    let media     = sbmec()!
    
    UIDevice.current.isProximityMonitoringEnabled = proximity
    battery.setPowerMode(0, error: nil)
    airplane.setInAirplaneMode(false)
    
    if !media.isPlaying() {
        media.togglePlayPause(forEventSource: 0)
    }
    
    backlight.turnOnScreenFully(withBacklightSource: 0)
    
    if !Preferences.shared.soft {
        IODeregisterForSystemPower(&object)
        IOServiceClose(connect)
    }
}

// Monitor battery to see if we should automatically sleep/wake

class BatteryHook: ClassHook<BCBatteryDevice> {
    typealias Group = Core
    
    func setPercentCharge(_ arg0: Int64) {
        orig.setPercentCharge(arg0)
        
        if arg0 == Preferences.shared.sleepPercent && !isHibernating && !recentWake && !didAutoSleep && !target.isCharging {
            didAutoSleep = true
            didAutoWake  = false
            
            IPC.shared.post("emt.paisseon.reverie.external")
        } else if arg0 == Preferences.shared.wakePercent && isHibernating && !didAutoWake && didAutoSleep {
            dehibernate()
            
            if Preferences.shared.soft {
                view.isHidden = true
                logo.isHidden = true
            }
            
            isHibernating = false
            didAutoSleep  = false
            didAutoWake   = true
        }
    }
    
    func isCharging() -> Bool {
        charging = orig.isCharging()
        return charging
    }
}

// Handle volume presses (i.e., force wake gesture)

class VolumeHook: ClassHook<SBVolumeControl> {
	typealias Group = Core
	
	func increaseVolume() {
        orig.increaseVolume()
        
        if isHibernating {
            wakePresses += 1
            
            if wakePresses == 3 {
                wakePresses   = 0
                isHibernating = false
                recentWake    = true
                view.isHidden = true
                logo.isHidden = true
                
                dehibernate()
            }
        }
	}
}

// Add the logo view to the screen if soft hibernation is enabled and handle hibernation notifications

class LogoHook: ClassHook<UIRootSceneWindow> {
	typealias Group = Core
	
	func initWithDisplayConfiguration(_ arg0: Any?) -> UIRootSceneWindow {
		IPC.shared.observe("emt.paisseon.reverie.external") { name in
			self.target.reverie_handleExternalNotification()
		}
		
		return orig.initWithDisplayConfiguration(arg0)
	}
	
	// orion:new
	@objc func reverie_handleExternalNotification() {
		isHibernating = true
		recentWake    = false
        
        if charging && !Preferences.shared.fastCharging {
            return
        }
		
		if Preferences.shared.soft {
			view.frame                    = UIScreen.main.bounds
			logo.image                    = UIImage(systemName: "moon.zzz.fill")
			logo.tintColor                = UIColor.white	
			view.backgroundColor          = UIColor.black
			view.isUserInteractionEnabled = false	
			logo.frame                    = CGRect(x: 0, y: 0, width: 50, height: 50)
			logo.center                   = target.center
			view.isHidden                 = false
			logo.isHidden                 = false
			
			target.addSubview(view)
			view.addSubview(logo)
			target.bringSubviewToFront(view)
			view.bringSubviewToFront(logo)
			
			hibernate(soft: true)
		} else {
			hibernate()
		}
	}
}

// Prevent screen from being turned on. Probably unnecessary

class BacklightHook: ClassHook<SBBacklightController> {
    typealias Group = Core
    
    func turnOnScreenFullyWithBacklightSource(_ arg0: Int64) {
        if isHibernating && !Preferences.shared.soft {
            return
        }
        
        orig.turnOnScreenFullyWithBacklightSource(arg0)
    }
}

class Reverie: Tweak {
	required init() {
        if Preferences.shared.enabled {
            Core().activate()
        }
	}
}