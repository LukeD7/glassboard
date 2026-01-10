import AppKit

// MARK: - Overlay Window (The dark background & selection logic)

class ScreenGrabOverlayWindow: NSWindow {
    init(frame: CGRect) {
        super.init(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .screenSaver
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isReleasedWhenClosed = false
        
        let view = ScreenGrabOverlayView(frame: frame)
        self.contentView = view
    }
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

class ScreenGrabOverlayView: NSView {
    var selectionRect: CGRect = .zero {
        didSet { needsDisplay = true }
    }
    
    var onSelectionComplete: ((CGRect) -> Void)?
    var onMouseDown: (() -> Void)?
    
    private var isDragging = false
    private var startPoint: CGPoint = .zero
    
    override func draw(_ dirtyRect: NSRect) {
        // Draw the dark overly with a "cut out" for the selection
        let path = NSBezierPath(rect: bounds)
        if !selectionRect.isEmpty {
            path.appendRect(selectionRect)
            path.windingRule = .evenOdd
        }
        
        NSColor.black.withAlphaComponent(0.4).setFill()
        path.fill()
        
        // Highlight the selection
        if !selectionRect.isEmpty {
            NSColor.white.setStroke()
            let border = NSBezierPath(rect: selectionRect)
            border.lineWidth = 1
            border.stroke()
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        onMouseDown?()
        startPoint = convert(event.locationInWindow, from: nil)
        selectionRect = .zero
        isDragging = true
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard isDragging else { return }
        let currentPoint = convert(event.locationInWindow, from: nil)
        
        let x = min(startPoint.x, currentPoint.x)
        let y = min(startPoint.y, currentPoint.y)
        let w = abs(startPoint.x - currentPoint.x)
        let h = abs(startPoint.y - currentPoint.y)
        
        selectionRect = CGRect(x: x, y: y, width: w, height: h)
    }
    
    override func mouseUp(with event: NSEvent) {
        isDragging = false
        if selectionRect.width > 5 && selectionRect.height > 5 {
            // Verify window is on screen
            if window?.screen != nil {
                onSelectionComplete?(selectionRect)
            }
        } else {
            selectionRect = .zero
        }
    }
}

// MARK: - Toolbar Window (The floating buttons)

protocol ScreenGrabToolbarDelegate: AnyObject {
    func toolbarDidSelectMode(_ mode: ScreenGrabMode)
    func toolbarDidClose()
}

class ScreenGrabToolbarWindow: NSPanel {
    weak var toolbarDelegate: ScreenGrabToolbarDelegate?
    
    init() {
        let width: CGFloat = 220 // Smaller, tighter toolbar
        let height: CGFloat = 44
        
        // Position at top center of main screen
        let screenFrame = NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1000, height: 800)
        let padding: CGFloat = 40
        // Top of screen is maxY.
        let frame = CGRect(x: screenFrame.midX - width/2, y: screenFrame.maxY - height - padding, width: width, height: height)
        
        super.init(contentRect: frame, styleMask: [.fullSizeContentView, .nonactivatingPanel], backing: .buffered, defer: false)
        
        self.level = .screenSaver + 1 // Above the overlay
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        self.isReleasedWhenClosed = false
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = 10
        contentView.layer?.masksToBounds = true
        self.contentView = contentView
        
        // Blur effect
        let visualEffect = NSVisualEffectView(frame: contentView.bounds)
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow
        visualEffect.autoresizingMask = [.width, .height]
        contentView.addSubview(visualEffect)
        
        setupButtons(in: visualEffect)
    }
    
    private var modeButtons: [ScreenGrabMode: NSButton] = [:]
    
    private func setupButtons(in parent: NSView) {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        stack.distribution = .fillProportionally
        stack.translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: parent.centerYAnchor),
            stack.centerXAnchor.constraint(equalTo: parent.centerXAnchor),
            stack.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        // Mode mapping with SF Symbols
        struct ModeConfig {
            let mode: ScreenGrabMode
            let icon: String
            let tooltip: String
        }
        
        let configs = [
            ModeConfig(mode: .selection, icon: "crop", tooltip: "Selection"),
            ModeConfig(mode: .window, icon: "macwindow", tooltip: "Window"),
            ModeConfig(mode: .fullscreen, icon: "display", tooltip: "Full Screen")
        ]
        
        // Modes
        for config in configs {
            let btn = NSButton()
            btn.bezelStyle = .regularSquare
            btn.setButtonType(.toggle)
            btn.isBordered = false
            btn.wantsLayer = true
            btn.layer?.backgroundColor = NSColor.clear.cgColor
            btn.layer?.cornerRadius = 6
            
            // Symbol configuration
            let symbolConfig = NSImage.SymbolConfiguration(pointSize: 15, weight: .medium)
            btn.image = NSImage(systemSymbolName: config.icon, accessibilityDescription: config.tooltip)?
                .withSymbolConfiguration(symbolConfig)
                
            btn.toolTip = config.tooltip
            btn.target = self
            btn.action = #selector(modeClicked(_:))
            btn.identifier = NSUserInterfaceItemIdentifier(config.mode.rawValue)
            
            // Layout
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.widthAnchor.constraint(equalToConstant: 36).isActive = true
            btn.heightAnchor.constraint(equalToConstant: 30).isActive = true
            
            stack.addArrangedSubview(btn)
            modeButtons[config.mode] = btn
        }
        
        // Separator
        let sep = NSBox()
        sep.boxType = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.widthAnchor.constraint(equalToConstant: 1).isActive = true
        sep.heightAnchor.constraint(equalToConstant: 16).isActive = true
        stack.addArrangedSubview(sep)
        
        // Close Button
        let closeBtn = NSButton()
        closeBtn.bezelStyle = .regularSquare
        closeBtn.isBordered = false
        closeBtn.wantsLayer = true
        closeBtn.layer?.backgroundColor = NSColor.clear.cgColor
        closeBtn.layer?.cornerRadius = 15 // Circle
        
        closeBtn.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Close")?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 18, weight: .regular))
        closeBtn.contentTintColor = .secondaryLabelColor
            
        closeBtn.target = self
        closeBtn.action = #selector(closeClicked)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.widthAnchor.constraint(equalToConstant: 30).isActive = true
        closeBtn.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        stack.addArrangedSubview(closeBtn)
    }
    
    func selectMode(_ mode: ScreenGrabMode) {
        // Update UI state with "glass" capsule style
        // We'll mimic the macOS Control Center look (active item has a light/dark background)
        for (m, btn) in modeButtons {
            let isSelected = (m == mode)
            btn.state = isSelected ? .on : .off
            
            // Visual state changes
            if isSelected {
                btn.layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.1).cgColor
                btn.contentTintColor = .labelColor
            } else {
                btn.layer?.backgroundColor = NSColor.clear.cgColor
                btn.contentTintColor = .secondaryLabelColor
            }
        }
    }
    
    @objc private func modeClicked(_ sender: NSButton) {
        guard let id = sender.identifier, let mode = ScreenGrabMode(rawValue: id.rawValue) else { return }
        selectMode(mode) // Update visual immediately
        toolbarDelegate?.toolbarDidSelectMode(mode)
    }
    
    @objc private func closeClicked() {
        toolbarDelegate?.toolbarDidClose()
    }
}
