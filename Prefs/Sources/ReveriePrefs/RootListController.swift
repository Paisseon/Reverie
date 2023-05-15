import JinxPrefs
import Preferences

final class RootListController: PSListController {
    override var specifiers: NSMutableArray? {
        get {
            if let specifiers = value(forKey: "_specifiers") as? NSMutableArray {
                return specifiers
            }
            
            var specifiers: NSMutableArray = .init()
            
            SpecifierFactory.add([
                GroupCell(name: "General", footerText: ""),
                ToggleCell(name: "Enable", key: "isEnabled", defaultValue: true)
            ], to: &specifiers, in: self)
            
            if PrefsHelper.getValue(for: "isEnabled", fallback: true) as? Bool == true {
                SpecifierFactory.add([
                    ToggleCell(name: "Fast Charge", key: "canFastCharge", defaultValue: true),
                    GroupCell(name: "Sleep Level", footerText: ""),
                    SliderCell(key: "sleepLevel", defaultValue: 7, range: 1 ..< 100),
                    GroupCell(name: "Wake Level", footerText: ""),
                    SliderCell(key: "wakeLevel", defaultValue: 20, range: 1 ..< 100)
                ], to: &specifiers, in: self)
            }
            
            SpecifierFactory.add([
                GroupCell(name: "", footerText: ""),
                ButtonCell(name: "Sleep Now", action: #selector(Self.sleepDart)),
                GroupCell(name: "Links", footerText: ""),
                ButtonCell(name: "Source Code", action: #selector(Self.openSource)),
                ButtonCell(name: "CyPwn's Discord", action: #selector(Self.openCyPwn)),
                GroupCell(name: "", footerText: poem)
            ], to: &specifiers, in: self)
            
            setValue(specifiers, forKey: "_specifiers")
            return specifiers
        }
        
        set { super.specifiers = newValue }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Metadata.developer = "Paisseon"
        Metadata.package = "lilliana.reverie"
        Metadata.tweakName = "Reverie"
		
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Apply",
            style: .done,
            target: self,
            action: #selector(respring)
        )
        
        table.tableHeaderView = HeaderView(style: .default, reuseIdentifier: "HeaderCell")
    }
    
    override func setPreferenceValue(_ value: Any, specifier: PSSpecifier) {
        super.setPreferenceValue(value, specifier: specifier)
        
        guard specifier.identifier == "isEnabled" else {
            return
        }
        
        if value as? Bool == true {
            var newSpecifiers: NSMutableArray = .init()
            
            SpecifierFactory.add([
                ToggleCell(name: "Fast Charge", key: "canFastCharge", defaultValue: true),
                GroupCell(name: "Sleep Level", footerText: ""),
                SliderCell(key: "sleepLevel", defaultValue: 7, range: 1 ..< 100),
                GroupCell(name: "Wake Level", footerText: ""),
                SliderCell(key: "wakeLevel", defaultValue: 20, range: 1 ..< 100)
            ], to: &newSpecifiers, in: self)
            
            self.insertContiguousSpecifiers(newSpecifiers as? [Any], afterSpecifierID: "isEnabled", animated: true)
        } else {
            let hiddenIDs: [Any] = self.specifiers(forIDs: ["canFastCharge", "Sleep Level", "sleepLevel", "Wake Level", "wakeLevel"])
            self.removeContiguousSpecifiers(hiddenIDs, animated: true)
        }
        
        table.tableHeaderView = HeaderView(style: .default, reuseIdentifier: nil)
    }
    
    @objc private func respring() {
        PrefsHelper.write()
        PrefsHelper.respring(withView: view)
    }
    
    @objc private func sleepDart() {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("lilliana.reverie.external" as CFString),
            nil,
            nil,
            true
        )
    }
    
    @objc private func openSource() {
        if let url: URL = .init(string: "https://github.com/Paisseon/Reverie") {
            UIApplication.shared.open(url)
        }
    }
    
    @objc private func openCyPwn() {
        if let url: URL = .init(string: "https://discord.gg/cypwn") {
            UIApplication.shared.open(url)
        }
    }
    
    private let poem: String = """
The search for meaning is a lonely journey
Through a world that's cold and unforgiving
We thought that we had found our freedom
But it was only an illusion, a fleeting moment of bliss

We left our past behind, thinking we could start anew
But the chains of our past lives still held us in their grip
No matter how far we ran, we could not escape
The ghosts of our past haunting us with every step we took
                          
We thought that freedom meant a chance to find our purpose
But what we found was only emptiness and despair
We realised that true freedom comes from within
From letting go of the pain and the hurt of our past
                          
Only then can we truly start to heal
And find the meaning and purpose that we seek
We must face our demons, and forgive those who have wronged us
In order to break the shackles that bind us and finally be free
"""
}
