import AppKit

/// The available screen capture modes, wrapping macOS screencapture utility
enum ScreenGrabMode: String, CaseIterable {
    case selection = "selection"      // Draw a rectangle area
    case window = "window"            // Select a window
    case fullscreen = "fullscreen"    // Capture full screen
    
    var displayName: String {
        switch self {
        case .selection: return "Selection (Draw Area)"
        case .window: return "Window"
        case .fullscreen: return "Full Screen"
        }
    }
    
    var shortcutHint: String {
        switch self {
        case .selection: return "⌘⇧C"
        case .window: return ""
        case .fullscreen: return ""
        }
    }
}

/// Manages screen capture functionality, wrapping macOS screencapture utility
/// Screenshots are always copied directly to clipboard for seamless UX
class ScreenGrabManager {
    static let shared = ScreenGrabManager()
    
    // MARK: - Persistence Keys
    private let lastModeKey = "ScreenGrabLastMode"
    
    /// The last used screen grab mode - persisted across sessions
    var lastUsedMode: ScreenGrabMode {
        get {
            if let stored = UserDefaults.standard.string(forKey: lastModeKey),
               let mode = ScreenGrabMode(rawValue: stored) {
                return mode
            }
            return .selection // Default to selection mode (most common use case)
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: lastModeKey)
        }
    }
    
    // MARK: - Screen Capture Methods
    
    /// Trigger screen capture using the last used mode
    func captureWithLastMode() {
        capture(mode: lastUsedMode)
    }
    
    /// Capture screen with specified mode
    /// - Parameter mode: The capture mode to use
    func capture(mode: ScreenGrabMode) {
        // Remember this mode for next time
        lastUsedMode = mode
        
        // Build the screencapture command
        // -c = copy to clipboard (always!)
        // -i = interactive mode (selection)
        // -w = window mode
        // No flag = full screen
        var arguments: [String] = ["-c"] // Always copy to clipboard
        
        switch mode {
        case .selection:
            arguments.append("-i")
            arguments.append("-s") // Selection mode within interactive
        case .window:
            arguments.append("-i")
            arguments.append("-w") // Window mode within interactive
        case .fullscreen:
            // No additional flags for full screen - just captures immediately
            break
        }
        
        // Run screencapture asynchronously
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            task.arguments = arguments
            
            do {
                try task.run()
                task.waitUntilExit()
                
                // Log result
                DispatchQueue.main.async {
                    if task.terminationStatus == 0 {
                        print("[ScreenGrab] Capture completed with mode: \(mode.rawValue)")
                    } else {
                        print("[ScreenGrab] Capture cancelled or failed")
                    }
                }
            } catch {
                print("[ScreenGrab] Error launching screencapture: \(error)")
            }
        }
    }
    
    /// Capture selection (draw rectangle area)
    func captureSelection() {
        capture(mode: .selection)
    }
    
    /// Capture a specific window
    func captureWindow() {
        capture(mode: .window)
    }
    
    /// Capture full screen
    func captureFullScreen() {
        capture(mode: .fullscreen)
    }
}
