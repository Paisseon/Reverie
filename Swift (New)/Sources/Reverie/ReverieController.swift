import ReverieC
import UIKit

// Globals for IOKit things

fileprivate var port    = IONotificationPortRef(bitPattern: 0)
fileprivate var connect = io_connect_t(0)
fileprivate var object  = io_object_t(0)

// Enum type for wake status

enum WakeStatus {
    case normal, autoSleep, autoWake, manuSleep, manuWake
}

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

final class ReverieController {
    static let shared = ReverieController()
    
    // Keep track of the current status
    
    public var isSleeping = false
    public var isCharging = false
    public var wakeStatus = WakeStatus.normal
    public var wakePress  = 0
    
    // Use these to restore the values of LPM, Airplane Mode, Proximity, and Media Playing
    
    public var proximitCache = false
    public var lowPowerCache = Int64(0)
    public var airplaneCache = false
    public var playingCache  = false
    
    private init() {}
    
    // Enable some battery savers and enter hibernation mode (using IOKit if soft hibernation is disabled)
    
    public func hibernate() {
        DispatchQueue.main.async {
            let airplane  = sbamc()!
            let backlight = sbblc()!
            let battery   = _cdbs()!
            let lock      = sblsm()!
            let media     = sbmec()!
            
            self.isSleeping = true
            
            self.proximitCache = UIDevice.current.isProximityMonitoringEnabled
            self.lowPowerCache = battery.getPowerMode()
            self.airplaneCache = airplane.isInAirplaneMode()
            self.playingCache  = media.isPlaying()
            
            UIDevice.current.isProximityMonitoringEnabled = false
            battery.setPowerMode(1, error: nil)
            airplane.setInAirplaneMode(true)
            
            if !lock.isUILocked() {
                lock.lockUI(fromSource: 2, withOptions: nil)
            }
            
            backlight._startFadeOutAnimation(fromLockSource: 0);
            
            if !Preferences.shared.soft {
                if media.isPlaying() {
                    media.togglePlayPause(forEventSource: 0)
                }
                
                connect = IORegisterForSystemPower(nil, &port, handlePowerChange, &object)
                
                if connect != 0 {
                    IOPMSleepSystem(connect)
                }
            }
        }
    }
    
    // Wake from hibernation status
    
    public func dehibernate() {
        DispatchQueue.main.async {
            let airplane  = sbamc()!
            let backlight = sbblc()!
            let battery   = _cdbs()!
            let lock      = sblsm()!
            let media     = sbmec()!
            
            if self.wakeStatus != .autoWake {
                self.wakeStatus = .manuWake
            }
            
            self.isSleeping = false
            
            UIDevice.current.isProximityMonitoringEnabled = self.proximitCache
            battery.setPowerMode(self.lowPowerCache, error: nil)
            airplane.setInAirplaneMode(self.airplaneCache)
            
            backlight.turnOnScreenFully(withBacklightSource: 0)
            lock.unlockUI(fromSource: 2, withOptions: nil)
            
            if !Preferences.shared.soft {
                if self.playingCache {
                    media.togglePlayPause(forEventSource: 0)
                }
                
                IODeregisterForSystemPower(&object)
                IOServiceClose(connect)
                connect = io_connect_t(0)
            }
        }
    }
}