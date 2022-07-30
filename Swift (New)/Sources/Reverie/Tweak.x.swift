import Orion
import ReverieC
import UIKit

struct Core: HookGroup {}

let rc      = ReverieController.shared
let logo    = UIImageView()
let view    = UIView()

// Monitor battery to see if we should automatically sleep/wake

class BatteryHook: ClassHook<BCBatteryDevice> {
    typealias Group = Core
    
    func setPercentCharge(_ arg0: Int64) {
        orig.setPercentCharge(arg0)
        
        // NOT manually woken, NOT auto-sleep
        
        if arg0 == Preferences.shared.sleepPercent && !rc.isSleeping && !rc.isCharging && rc.wakeStatus != .manuWake && rc.wakeStatus != .autoSleep {
            rc.wakeStatus = .autoSleep
            IPC.shared.post("emt.paisseon.reverie.external")
            
            return
        }
        
        if arg0 == Preferences.shared.wakePercent && rc.isSleeping && rc.wakeStatus == .autoSleep {
            if Preferences.shared.soft {
                view.isHidden = true
                logo.isHidden = true
            }
            
            rc.wakeStatus = .autoWake
            
            rc.dehibernate()
        }
    }
    
    func setCharging(_ arg0: Bool) {
        orig.setCharging(arg0)
        
        rc.isCharging = arg0
    }
}

// Handle volume presses (i.e., force wake gesture)

class VolumeHook: ClassHook<SBVolumeHardwareButton> {
	typealias Group = Core
	
	func volumeIncreasePress(_ arg0: Any?) {
        if rc.isSleeping {
            rc.wakePress += 1
            
            if rc.wakePress >= 3 {
                rc.wakePress  = 0
                rc.wakeStatus = .manuWake
                view.isHidden = true
                logo.isHidden = true
                
                rc.dehibernate()
            }
        } else {
            orig.volumeIncreasePress(arg0)
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
        DispatchQueue.main.async {
		    rc.wakeStatus = .normal
            
            if rc.isCharging && !Preferences.shared.fastCharging {
                return
            }
		    
		    if Preferences.shared.soft {
			    view.frame                    = UIScreen.main.bounds
			    logo.image                    = UIImage(systemName: "moon.zzz.fill")
			    logo.tintColor                = UIColor.white	
			    view.backgroundColor          = UIColor.black
			    view.isUserInteractionEnabled = false	
			    logo.frame                    = CGRect(x: 0, y: 0, width: 50, height: 50)
			    logo.center                   = self.target.center
			    view.isHidden                 = false
			    logo.isHidden                 = false
			    
			    self.target.addSubview(view)
			    view.addSubview(logo)
			    self.target.bringSubviewToFront(view)
			    view.bringSubviewToFront(logo)
		    }
            
            rc.hibernate()
        }
	}
}

// Prevent screen from being turned on. Probably unnecessary

class BacklightHook: ClassHook<SBBacklightController> {
    typealias Group = Core
    
    func turnOnScreenFullyWithBacklightSource(_ arg0: Int64) {
        if rc.isSleeping && !Preferences.shared.soft {
            return
        }
        
        orig.turnOnScreenFullyWithBacklightSource(arg0)
    }
}

// Constructor

class Reverie: Tweak {
	required init() {
        if Preferences.shared.enabled {
            Core().activate()
        }
	}
}