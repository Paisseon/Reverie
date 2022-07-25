import Cephei

class Preferences {
	static let shared = Preferences()
	
	private let preferences = HBPreferences(identifier: "emt.paisseon.reverie")
    
    private(set) var enabled      = true
    private(set) var fastCharging = false
    private(set) var soft         = false
    private(set) var sleepPercent = 7
    private(set) var wakePercent  = 20
    
	private var enabledI      : ObjCBool = true
	private var fastChargingI : ObjCBool = false
	private var softI         : ObjCBool = false
	
	private init() {
		preferences.register(defaults: [
			"enabled"      : true,
			"fastCharging" : false,
			"soft"         : false,
			"sleepPercent" : 7,
			"wakePercent"  : 20,
		])
	
		preferences.register(_Bool:   &enabledI,      default: true,  forKey: "enabled")
		preferences.register(_Bool:   &fastChargingI, default: false, forKey: "fastCharging")
		preferences.register(_Bool:   &softI,         default: false, forKey: "youGaveYourHibernateToMeSoftly")
		preferences.register(integer: &sleepPercent,  default: 7,     forKey: "sleepPercent")
		preferences.register(integer: &wakePercent,   default: 20,    forKey: "wakePercent")
        
        enabled      = enabledI.boolValue
        fastCharging = fastChargingI.boolValue
        soft         = softI.boolValue
	}
}
