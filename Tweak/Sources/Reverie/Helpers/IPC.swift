import CoreFoundation

final class IPC {
    static let shared: IPC = .init()
    var observers: [String: (String) -> Void] = [:]
    
    func observe(_ name: String, handler: @escaping (String) -> Void) {
        observers[name] = handler
        
        let callback: CFNotificationCallback = { _, _, name, _, _ in
            guard let name: String = name?.rawValue as? String else {
                return
            }
            
            IPC.shared.observers[name]?(name)
        }
        
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            callback,
            getCFString(from: name),
            nil,
            .deliverImmediately
        )
    }
    
    func post(_ name: String) {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(getCFString(from: name)),
            nil,
            nil,
            true
        )
    }
    
    private func getCFString(from str: String) -> CFString {
        let cString: UnsafeMutablePointer<Int8> = strdup(str)
        return CFStringCreateWithCString(nil, cString, CFStringBuiltInEncodings.UTF8.rawValue)
    }
}
