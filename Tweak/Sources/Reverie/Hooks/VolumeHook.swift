import Jinx
import ObjectiveC

struct VolumeHook: Hook {
    typealias T = @convention(c) (AnyObject, Selector, Any?) -> Void
    
    let cls: AnyClass? = objc_lookUpClass("SBVolumeHardwareButton")
    let sel: Selector = sel_registerName("volumeIncreasePress:")
    let replace: T = { obj, sel, a0 in
        if Reverie.status == .autoSlept || Reverie.status == .userSlept {
            if Reverie.wakePress > 3 {
                Reverie.wakePress = 0
                Reverie.status = .userWoken
                Reverie.wake()
            } else {
                Reverie.wakePress += 1
            }
        }
        
        orig(obj, sel, a0)
    }
}
