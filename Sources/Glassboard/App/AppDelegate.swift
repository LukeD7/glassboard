import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    
    var statusItem: NSStatusItem!
    var panel: FloatingPanel!
    var panelController: HistoryViewController!
    
    // Wider panel for comfortable text reading
    private let panelWidth: CGFloat = 440
    private let panelHeight: CGFloat = 520
    
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
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePanel()
        }
    }
    
    private func showContextMenu() {
        let menu = NSMenu()
        
        // Screen Grab section header
        let headerItem = NSMenuItem(title: "Screen Grab", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        
        // Screen grab options with checkmarks for last used mode
        let lastMode = ScreenGrabManager.shared.lastUsedMode
        
        let selectionItem = NSMenuItem(title: "Selection (Draw Area)", action: #selector(captureSelection), keyEquivalent: "")
        selectionItem.target = self
        selectionItem.state = lastMode == .selection ? .on : .off
        menu.addItem(selectionItem)
        
        let windowItem = NSMenuItem(title: "Window", action: #selector(captureWindow), keyEquivalent: "")
        windowItem.target = self
        windowItem.state = lastMode == .window ? .on : .off
        menu.addItem(windowItem)
        
        let fullscreenItem = NSMenuItem(title: "Full Screen", action: #selector(captureFullScreen), keyEquivalent: "")
        fullscreenItem.target = self
        fullscreenItem.state = lastMode == .fullscreen ? .on : .off
        menu.addItem(fullscreenItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quick capture with last mode
        let quickCaptureItem = NSMenuItem(title: "Quick Capture (⌘⇧C)", action: #selector(triggerScreenGrab), keyEquivalent: "")
        quickCaptureItem.target = self
        menu.addItem(quickCaptureItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Show clipboard history
        let historyItem = NSMenuItem(title: "Clipboard History (⌘⇧V)", action: #selector(togglePanel), keyEquivalent: "")
        historyItem.target = self
        menu.addItem(historyItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Clear history
        let clearItem = NSMenuItem(title: "Clear History...", action: #selector(clearHistoryWithConfirmation), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit Glassboard", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil // Reset so left-click works normally
    }
    
    // MARK: - Screen Grab Actions
    
    @objc func triggerScreenGrab() {
        ScreenGrabManager.shared.captureWithLastMode()
    }
    
    @objc func captureSelection() {
        ScreenGrabManager.shared.captureSelection()
    }
    
    @objc func captureWindow() {
        ScreenGrabManager.shared.captureWindow()
    }
    
    @objc func captureFullScreen() {
        ScreenGrabManager.shared.captureFullScreen()
    }
    
    @objc func clearHistoryWithConfirmation() {
        let alert = NSAlert()
        alert.messageText = "Clear Clipboard History?"
        alert.informativeText = "This will permanently delete all clipboard history items. Pinned items will also be removed. This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Clear History")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            ClipboardManager.shared.clearHistory()
        }
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    private func setupPanel() {
        panelController = HistoryViewController()
        panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight))
        panel.contentViewController = panelController
        panel.delegate = self
    }
    
    private func setupHotkey() {
        HotKeyManager.shared.onPasteTrigger = { [weak self] in
            self?.togglePanel()
        }
        HotKeyManager.shared.onScreenGrabTrigger = { [weak self] in
            self?.triggerScreenGrab()
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
        
        // Position near cursor for quick access - follows the user's focus
        let mouseLocation = NSEvent.mouseLocation
        var targetPoint: NSPoint
        
        // Find which screen the cursor is on
        let currentScreen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) } ?? NSScreen.main
        
        if let screen = currentScreen {
            let screenRect = screen.visibleFrame
            
            // Position panel centered horizontally on cursor, slightly above
            // This puts it right where the user is working
            var x = mouseLocation.x - (panelWidth / 2)
            var y = mouseLocation.y + 20 // Slightly above cursor
            
            // If panel would go off top, put it below cursor instead
            if y + panelHeight > screenRect.maxY {
                y = mouseLocation.y - panelHeight - 20
            }
            
            // Clamp to screen bounds
            x = max(screenRect.minX + 10, min(x, screenRect.maxX - panelWidth - 10))
            y = max(screenRect.minY + 10, min(y, screenRect.maxY - panelHeight - 10))
            
            targetPoint = NSPoint(x: x, y: y)
        } else {
            targetPoint = NSPoint(x: mouseLocation.x - panelWidth / 2, y: mouseLocation.y + 20)
        }
        
        panel.setFrameOrigin(targetPoint)
        
        NSApp.activate(ignoringOtherApps: true)
        
        let centerPoint = NSPoint(x: panel.frame.midX, y: panel.frame.midY)
        panel.showWithAnimation(from: centerPoint)
        
        panelController.refreshData()
    }
    
    private func closePanel() {
        panel.hideWithAnimation(completion: nil)
    }
    
    // MARK: - NSWindowDelegate
    
    func windowDidResignKey(_ notification: Notification) {
        guard notification.object as? NSPanel === panel, panel.isVisible else { return }
        closePanel()
    }
}
