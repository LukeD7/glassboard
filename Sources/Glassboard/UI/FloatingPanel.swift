import AppKit

class FloatingPanel: NSPanel {
    
    private var isAnimating = false
    
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        
        // Window level - statusBar ensures it floats above most windows
        self.level = .statusBar
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        self.isMovableByWindowBackground = false
        self.isReleasedWhenClosed = false
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.hidesOnDeactivate = false
        
        // Transparent titlebar
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        
        // Round corners on the content view
        self.contentView?.wantsLayer = true
        self.contentView?.layer?.cornerRadius = 12
        self.contentView?.layer?.masksToBounds = true
        self.contentView?.layer?.cornerCurve = .continuous
    }
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    
    // MARK: - Animated Show/Hide
    
    func showWithAnimation(from centerPoint: NSPoint) {
        guard !isAnimating else { return }
        isAnimating = true
        
        let finalFrame = self.frame
        
        // Start slightly scaled down and faded - subtle like Spotlight
        let startScale: CGFloat = 0.96
        let startFrame = NSRect(
            x: finalFrame.midX - (finalFrame.width * startScale) / 2,
            y: finalFrame.midY - (finalFrame.height * startScale) / 2,
            width: finalFrame.width * startScale,
            height: finalFrame.height * startScale
        )
        
        self.setFrame(startFrame, display: false)
        self.alphaValue = 0
        self.makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.16
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            context.allowsImplicitAnimation = true
            
            self.animator().setFrame(finalFrame, display: true)
            self.animator().alphaValue = 1.0
        }, completionHandler: { [weak self] in
            self?.isAnimating = false
        })
    }
    
    func hideWithAnimation(completion: (() -> Void)? = nil) {
        guard !isAnimating else {
            completion?()
            return
        }
        isAnimating = true
        
        let currentFrame = self.frame
        let endScale: CGFloat = 0.96
        let endFrame = NSRect(
            x: currentFrame.midX - (currentFrame.width * endScale) / 2,
            y: currentFrame.midY - (currentFrame.height * endScale) / 2,
            width: currentFrame.width * endScale,
            height: currentFrame.height * endScale
        )
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.12
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            context.allowsImplicitAnimation = true
            
            self.animator().setFrame(endFrame, display: true)
            self.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.orderOut(nil)
            self?.alphaValue = 1.0
            self?.setFrame(currentFrame, display: false)
            self?.isAnimating = false
            completion?()
        })
    }
}
