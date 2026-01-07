import Carbon
import AppKit

class HotKeyManager {
    static let shared = HotKeyManager()
    var onTrigger: (() -> Void)?
    private var hotKeyRef: EventHotKeyRef?

    func register() {
        // Register Command + Shift + V
        // kVK_ANSI_V = 0x09
        let keyCode = UInt32(0x09)
        let modifiers = UInt32(cmdKey | shiftKey)
        
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x474C5353) // 'GLSS'
        hotKeyID.id = 1
        
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        if status != noErr {
            print("Error registering hotkey: \(status)")
            return
        }

        // Install Handler
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        InstallEventHandler(GetApplicationEventTarget(), { (handler, event, userData) -> OSStatus in
            // Dispatch to main thread to be safe
            DispatchQueue.main.async {
                HotKeyManager.shared.onTrigger?()
            }
            return noErr
        }, 1, &eventSpec, nil, nil)
    }
}
