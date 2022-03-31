import Orion
import ReverieC
import UIKit
import CoreFoundation

struct Main: HookGroup {}

var isHibernating = false
var recentWake    = false
var didAutoWake   = false
var didAutoSleep  = false
var wakePresses   = 0
let logo          = UIImageView()
let view          = UIView()

class BatteryHook: ClassHook<_UIBatteryView> {
	typealias Group = Main
	
	func chargePercent() -> Double {
		let currentBattery = orig.chargePercent()
		
		if target.chargingState == 1 && !Preferences.shared.fastCharging.boolValue {
			return currentBattery
		}
		
		if Int(currentBattery * 100) == Preferences.shared.sleepPercent && !isHibernating && !recentWake && !didAutoSleep {
			didAutoSleep = true
			didAutoWake  = false
			
			CFNotificationCenterPostNotification(
				CFNotificationCenterGetDarwinNotifyCenter(),
				CFNotificationName("emt.paisseon.reverie.external" as CFString),
				nil,
				nil,
				true
			)
		} else if Int(currentBattery * 100) == Preferences.shared.wakePercent && isHibernating && !didAutoWake {
			dehibernate()
			
			if Preferences.shared.viewOnPower.boolValue {
				view.isHidden                             = true
				logo.isHidden                             = true
			}
			
			UIDevice.current.isProximityMonitoringEnabled = true
			isHibernating                                 = false
			didAutoWake                                   = true
			didAutoSleep                                  = false
		}
		
		return currentBattery
	}
}

class VolumeHook: ClassHook<NSObject> {
	typealias Group       = Main
	static let targetName = "SBVolumeControl"
	
	func increaseVolume() {
		if isHibernating {
			wakePresses += 1
			
			if wakePresses == 3 {
				wakePresses                                   = 0
				UIDevice.current.isProximityMonitoringEnabled = true
				isHibernating                                 = false
				recentWake                                    = true
				
				if Preferences.shared.viewOnPower.boolValue {
					view.isHidden                             = true
					logo.isHidden                             = true
				}
				
				dehibernate()
			}
		} else {
			orig.increaseVolume()
		}
	}
}

class LogoHook: ClassHook<UIRootSceneWindow> {
	typealias Group = Main
	
	func initWithDisplayConfiguration(_ arg0: Any?) -> UIRootSceneWindow {
		IPC.shared.addObserver(as: "emt.paisseon.reverie.external") { name in
			self.target.reverie_handleExternalNotification()
		}
		
		return orig.initWithDisplayConfiguration(arg0)
	}
	
	// orion:new
	@objc func reverie_handleExternalNotification() {
		isHibernating                     = true
		recentWake                        = false
		
		if Preferences.shared.viewOnPower.boolValue {
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
			
			soft_hibernate()
		} else {
			hibernate()
		}
	}
}

class BacklightHook: ClassHook<NSObject> {
	typealias Group       = Main
	static let targetName = "SBBacklightController"
	
	func turnOnScreenFullyWithBacklightSource(_ arg0: Int64) {
		if isHibernating && !Preferences.shared.viewOnPower.boolValue {
			return
		}
		
		orig.turnOnScreenFullyWithBacklightSource(arg0)
	}
}

class Reverie: Tweak {
	required init() {
		if Preferences.shared.enabled.boolValue {
			Main().activate()
		}
	}
}