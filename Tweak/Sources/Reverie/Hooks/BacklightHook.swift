import Jinx
import ObjectiveC
import ReverieImports

struct BacklightHook: Hook {
    typealias T = @convention(c) (AnyObject, Selector, Int64) -> Void
    
    let cls: AnyClass? = SBBacklightController.self
    let sel: Selector = #selector(SBBacklightController.turnOnScreenFully)
    let replace: T = { obj, sel, source in
        guard Reverie.status != .autoSlept && Reverie.status != .userSlept else {
            return
        }
        
        orig(obj, sel, source)
    }
}
