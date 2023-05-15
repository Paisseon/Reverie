import Jinx
import UIKit

struct Tweak {
    static func ctor() {
        guard Preferences.isEnabled else {
            return
        }
        
        BacklightHook().hook()
        VolumeHook().hook()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            UIDevice.current.isBatteryMonitoringEnabled = true
            
            NotificationCenter.default.addObserver(
                forName: UIDevice.batteryLevelDidChangeNotification,
                object: nil,
                queue: nil
            ) { _ in
                guard !Reverie.isCharging || Preferences.canFastCharge else {
                    return
                }
                
                let batteryLevel: Int = .init(UIDevice.current.batteryLevel * 100.0)
                
                if batteryLevel == Preferences.sleepLevel && (Reverie.status == .autoWoken || Reverie.status == .dreamless) {
                    Reverie.status = .autoSlept
                    Reverie.sleep()
                } else if batteryLevel == Preferences.wakeLevel && (Reverie.status == .autoSlept || Reverie.status == .userSlept) {
                    Reverie.status = .autoWoken
                    Reverie.wake()
                }
            }
            
            IPC.shared.observe("lilliana.reverie.external") { _ in
                Reverie.status = .userSlept
                Reverie.sleep()
            }
        }
    }
}

@_cdecl("jinx_entry")
func jinxEntry() {
    Tweak.ctor()
}
