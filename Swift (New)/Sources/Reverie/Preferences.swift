import Cephei

class Preferences {
	static let shared = Preferences()
	
	private let preferences                  = HBPreferences(identifier: "emt.paisseon.reverie")
	private(set) var enabled      : ObjCBool = true
	private(set) var fastCharging : ObjCBool = true
	private(set) var viewOnPower  : ObjCBool = false
	private(set) var sleepPercent : Int      = 7
	private(set) var wakePercent  : Int      = 20
	
	private init() {
		preferences.register(defaults: [
			"enabled" : true,
			"fastCharging" : true,
			"viewOnPower" : false,
			"sleepPercent" : 7,
			"wakePercent" : 20,
		])
	
		preferences.register(_Bool: &enabled, default: true, forKey: "enabled")
		preferences.register(_Bool: &fastCharging, default: true, forKey: "fastCharging")
		preferences.register(_Bool: &viewOnPower, default: false, forKey: "viewOnPower")
		preferences.register(integer: &sleepPercent, default: 7, forKey: "sleepPercent")
		preferences.register(integer: &wakePercent, default: 20, forKey: "wakePercent")
	}
}
