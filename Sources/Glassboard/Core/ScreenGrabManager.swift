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
    
    // MARK: - UI Sessions
    private var overlayWindow: ScreenGrabOverlayWindow?
    private var toolbarWindow: ScreenGrabToolbarWindow?
    
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
    
    /// Start the interactive capture session
    func startSession() {
        // If session is already active, bring to front or restart?
        closeSession()
        
        DispatchQueue.main.async {
            self.setupSession()
        }
    }
    
    private func setupSession() {
        // Create Overlay (Cover all screens or just main? Main for simplicity for now)
        guard let screen = NSScreen.main else { return }
        let frame = screen.frame
        
        let overlay = ScreenGrabOverlayWindow(frame: frame)
        if let view = overlay.contentView as? ScreenGrabOverlayView {
            view.onSelectionComplete = { [weak self] rect in
                self?.captureSelection(rect: rect, screenHeight: frame.height)
            }
        }
        
        let toolbar = ScreenGrabToolbarWindow()
        toolbar.toolbarDelegate = self
        
        self.overlayWindow = overlay
        self.toolbarWindow = toolbar
        
        // Ensure app is active so it receives the first click immediately
        NSApp.activate(ignoringOtherApps: true)
        
        // Always start the UI in selection mode (drawing state)
        // because the overlay itself provides the selection interface.
        // Other modes are triggered by switching away from this state.
        toolbar.selectMode(.selection)
        
        overlay.makeKeyAndOrderFront(nil)
        toolbar.makeKeyAndOrderFront(nil)
    }
    
    func closeSession() {
        overlayWindow?.close()
        overlayWindow = nil
        toolbarWindow?.close()
        toolbarWindow = nil
    }

    private func captureSelection(rect: CGRect, screenHeight: CGFloat) {
        // Convert to standard coordinates for screencapture (Top-Left origin)
        // detailed rect format is x,y,w,h
        let flippedY = screenHeight - rect.maxY
        let rectString = "\(Int(rect.origin.x)),\(Int(flippedY)),\(Int(rect.width)),\(Int(rect.height))"
        
        // Hide UI during capture (though we are capturing a rect based on overlay, 
        // the overlay itself is transparent/dim. We want to capture what's UNDER it.)
        // But screencapture -R captures the screen content.
        // We must close the overlay before capturing?
        // If we close overlay, the dimming goes away, proving the "true" screen.
        // Yes, close session first.
        closeSession()
        
        // Slight delay to ensure window is gone?
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.performProcessCapture(arguments: ["-c", "-R", rectString])
        }
    }
    
    private func performProcessCapture(arguments: [String]) {
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            task.arguments = arguments
            
            do {
                try task.run()
                task.waitUntilExit()
                
                DispatchQueue.main.async {
                    if task.terminationStatus == 0 {
                        print("[ScreenGrab] Capture completed")
                    } else {
                        print("[ScreenGrab] Capture cancelled or failed")
                    }
                }
            } catch {
                print("[ScreenGrab] Error launching screencapture: \(error)")
            }
        }
    }
}

extension ScreenGrabManager: ScreenGrabToolbarDelegate {
    func toolbarDidSelectMode(_ mode: ScreenGrabMode) {
        lastUsedMode = mode
        
        switch mode {
        case .selection:
            // Remain in session, ready to draw
            break
        case .window:
            closeSession()
            // -i -w : Interactive Window Selection
            // -c : Copy
            performProcessCapture(arguments: ["-c", "-i", "-w"])
        case .fullscreen:
            closeSession()
            // -c : Copy (Fullscreen default)
            performProcessCapture(arguments: ["-c"])
        }
    }
    
    func toolbarDidClose() {
        closeSession()
    }
}
