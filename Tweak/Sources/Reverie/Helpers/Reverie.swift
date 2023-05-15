import IOKit
import UIKit
import ReverieImports

private func powerChangeCallback(
    refcon _: UnsafeMutableRawPointer?,
    service _: io_service_t,
    messageType: natural_t,
    messageArgument _: UnsafeMutableRawPointer?
) {
    if Reverie.connect != 0 {
        switch messageType {
            case 0x280:
                IOAllowPowerChange(Reverie.connect, Int(messageType))
            case 0x320:
                IOCancelPowerChange(Reverie.connect, Int(messageType))
                fallthrough
            default:
                IOPMSleepSystem(Reverie.connect)
        }
    }
}

struct Reverie {
    static var status: SleepStatus = .dreamless
    static var isCharging: Bool { UIDevice.current.batteryState == .charging }
    static var wakePress: Int = 0
    
    static func sleep() {
        if let airplaneMode: SBAirplaneModeController = .sharedInstance(),
           let backlight: SBBacklightController = .sharedInstance(),
           let lockScreen: SBLockScreenManager = .sharedInstance(),
           let media: SBMediaController = .sharedInstance()
        {
            apmCache = airplaneMode.isInAirplaneMode()
            lpmCache = ProcessInfo.processInfo.isLowPowerModeEnabled
            medCache = media.isPlaying()
            
            PSLowPowerModeSettingsDetail.setEnabled(true)
            IOPMSetAggressiveness(connect, UInt(kPMSetAggressiveness), 0)
            airplaneMode.setInAirplaneMode(true)
            
            if !lockScreen.isUILocked() {
                lockScreen.lockUI(fromSource: 2, withOptions: nil)
            }
            
            if medCache {
                media.togglePlayPause(forEventSource: 0)
            }
            
            backlight._startFadeOutAnimation(fromLockSource: 0)
        }
        
        UIAccessibility.requestGuidedAccessSession(enabled: true, completionHandler: { _ in })
        UIDevice.current.isProximityMonitoringEnabled = false
        connect = IORegisterForSystemPower(nil, &port, powerChangeCallback(refcon:service:messageType:messageArgument:), &object)
        
        if connect != 0 {
            IOPMSleepSystem(connect)
        }
    }
    
    static func wake() {
        if let airplaneMode: SBAirplaneModeController = .sharedInstance(),
           let backlight: SBBacklightController = .sharedInstance(),
           let lockScreen: SBLockScreenManager = .sharedInstance(),
           let media: SBMediaController = .sharedInstance()
        {
            airplaneMode.setInAirplaneMode(apmCache)
            PSLowPowerModeSettingsDetail.setEnabled(lpmCache)
            
            if medCache {
                media.togglePlayPause(forEventSource: 0)
            }
            
            backlight.turnOnScreenFully(withBacklightSource: 0)
            lockScreen.unlockUI(fromSource: 2, withOptions: nil)
        }
        
        UIAccessibility.requestGuidedAccessSession(enabled: false, completionHandler: { _ in })
        IODeregisterForSystemPower(&object)
        IOServiceClose(connect)
        
        connect = io_connect_t(0)
        
        if status == .userWoken {
            DispatchQueue.main.asyncAfter(deadline: .now() + 600) {
                Reverie.status = .dreamless
            }
        }
    }
    
    fileprivate static var connect: io_connect_t = .init(0)
    private static var port: IONotificationPortRef? = .init(bitPattern: 0)
    private static var object: io_object_t = .init(0)
    
    private static var apmCache: Bool = false
    private static var lpmCache: Bool = false
    private static var medCache: Bool = false
}
