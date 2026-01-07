import Carbon
import AppKit

/// Hotkey identifiers for different actions
enum HotKeyAction: UInt32 {
    case paste = 1          // Command + Shift + V - Open paste panel
    case screenGrab = 2     // Command + Shift + C - Trigger screen grab
}

class HotKeyManager {
    static let shared = HotKeyManager()
    
    /// Callback for paste panel hotkey (Command + Shift + V)
    var onPasteTrigger: (() -> Void)?
    
    /// Callback for screen grab hotkey (Command + Shift + C)
    var onScreenGrabTrigger: (() -> Void)?
    
    private var pasteHotKeyRef: EventHotKeyRef?
    private var screenGrabHotKeyRef: EventHotKeyRef?
    private var handlerInstalled = false

    func register() {
        // Install the event handler once for all hotkeys
        if !handlerInstalled {
            installHandler()
            handlerInstalled = true
        }
        
        registerPasteHotKey()
        registerScreenGrabHotKey()
    }
    
    private func installHandler() {
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        InstallEventHandler(GetApplicationEventTarget(), { (handler, event, userData) -> OSStatus in
            // Extract which hotkey was pressed
            var hotKeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            
            DispatchQueue.main.async {
                guard let action = HotKeyAction(rawValue: hotKeyID.id) else { return }
                
                switch action {
                case .paste:
                    HotKeyManager.shared.onPasteTrigger?()
                case .screenGrab:
                    HotKeyManager.shared.onScreenGrabTrigger?()
                }
            }
            return noErr
        }, 1, &eventSpec, nil, nil)
    }
    
    private func registerPasteHotKey() {
        // Register Command + Shift + V
        // kVK_ANSI_V = 0x09
        let keyCode = UInt32(0x09)
        let modifiers = UInt32(cmdKey | shiftKey)
        
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x474C5353) // 'GLSS'
        hotKeyID.id = HotKeyAction.paste.rawValue
        
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &pasteHotKeyRef)
        
        if status != noErr {
            print("[HotKey] Error registering paste hotkey: \(status)")
        } else {
            print("[HotKey] Registered ⌘⇧V for paste panel")
        }
    }
    
    private func registerScreenGrabHotKey() {
        // Register Command + Shift + C
        // kVK_ANSI_C = 0x08
        let keyCode = UInt32(0x08)
        let modifiers = UInt32(cmdKey | shiftKey)
        
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x474C5353) // 'GLSS'
        hotKeyID.id = HotKeyAction.screenGrab.rawValue
        
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &screenGrabHotKeyRef)
        
        if status != noErr {
            print("[HotKey] Error registering screen grab hotkey: \(status)")
        } else {
            print("[HotKey] Registered ⌘⇧C for screen grab")
        }
    }
}
