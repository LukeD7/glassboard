import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    
    var statusItem: NSStatusItem!
    var panel: FloatingPanel!
    var panelController: HistoryViewController!
    
    // Maccy-inspired dimensions: tall and narrow for quick scanning
    private let panelWidth: CGFloat = 360
    private let panelHeight: CGFloat = 480
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        setupMenu()
        setupPanel()
        setupHotkey()
        
        ClipboardManager.shared.startMonitoring()
    }
    
    private func setupMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Glassboard")?
                .withSymbolConfiguration(config)
            button.action = #selector(togglePanel)
            button.target = self
        }
    }
    
    private func setupPanel() {
        panelController = HistoryViewController()
        panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight))
        panel.contentViewController = panelController
        panel.delegate = self
    }
    
    private func setupHotkey() {
        HotKeyManager.shared.onTrigger = { [weak self] in
            self?.togglePanel()
        }
        HotKeyManager.shared.register()
    }
    
    @objc func togglePanel() {
        if panel.isVisible {
            closePanel()
        } else {
            openPanel()
        }
    }
    
    private func openPanel() {
        panel.setContentSize(NSSize(width: panelWidth, height: panelHeight))
        
        // Position near cursor for quick access (Maccy-style option)
        let mouseLocation = NSEvent.mouseLocation
        var targetPoint: NSPoint
        
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            
            // Smart positioning: centered horizontally, upper third of screen
            // This mimics Spotlight behavior which feels natural
            let x = screenRect.midX - (panelWidth / 2)
            let y = screenRect.maxY - panelHeight - (screenRect.height * 0.15)
            
            // Clamp to screen bounds
            targetPoint = NSPoint(
                x: max(screenRect.minX, min(x, screenRect.maxX - panelWidth)),
                y: max(screenRect.minY, min(y, screenRect.maxY - panelHeight))
            )
        } else {
            targetPoint = NSPoint(x: mouseLocation.x - panelWidth / 2, y: mouseLocation.y - panelHeight)
        }
        
        panel.setFrameOrigin(targetPoint)
        
        NSApp.activate(ignoringOtherApps: true)
        
        let centerPoint = NSPoint(x: panel.frame.midX, y: panel.frame.midY)
        panel.showWithAnimation(from: centerPoint)
        
        panelController.refreshData()
    }
    
    private func closePanel() {
        panel.hideWithAnimation {
            NSApp.hide(nil)
        }
    }
    
    // MARK: - NSWindowDelegate
    
    func windowDidResignKey(_ notification: Notification) {
        guard notification.object as? NSPanel === panel, panel.isVisible else { return }
        closePanel()
    }
}
