import AppKit

class HistoryCell: NSTableCellView {
    static let identifier = NSUserInterfaceItemIdentifier("HistoryCell")
    
    // Padding matches Maccy's Popup.horizontalPadding
    private static let horizontalPadding: CGFloat = 5
    private static let cornerRadius: CGFloat = 6
    
    private let contentBackground = NSView()
    private let previewLabel = NSTextField(labelWithString: "")
    private let previewImageView = NSImageView()
    private let pinIcon = NSImageView()
    
    private var trackingArea: NSTrackingArea?
    private var isHovered = false
    private var currentItem: ClipboardItem?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        wantsLayer = true
        
        // Selection/hover background
        contentBackground.translatesAutoresizingMaskIntoConstraints = false
        contentBackground.wantsLayer = true
        contentBackground.layer?.cornerRadius = Self.cornerRadius
        contentBackground.layer?.cornerCurve = .continuous
        contentBackground.alphaValue = 0
        addSubview(contentBackground)
        
        // Pin indicator (small, left side)
        pinIcon.translatesAutoresizingMaskIntoConstraints = false
        pinIcon.image = NSImage(systemSymbolName: "pin.fill", accessibilityDescription: "Pinned")
        pinIcon.contentTintColor = .systemOrange
        pinIcon.imageScaling = .scaleProportionallyDown
        pinIcon.isHidden = true
        addSubview(pinIcon)
        
        // Main text preview - the hero
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        previewLabel.lineBreakMode = .byTruncatingTail
        previewLabel.maximumNumberOfLines = 1
        previewLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        previewLabel.textColor = .labelColor
        previewLabel.cell?.truncatesLastVisibleLine = true
        previewLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        addSubview(previewLabel)
        
        // Image preview
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        previewImageView.imageScaling = .scaleProportionallyUpOrDown
        previewImageView.wantsLayer = true
        previewImageView.layer?.cornerRadius = 4
        previewImageView.layer?.cornerCurve = .continuous
        previewImageView.layer?.masksToBounds = true
        addSubview(previewImageView)
        
        NSLayoutConstraint.activate([
            // Background fills cell with padding
            contentBackground.topAnchor.constraint(equalTo: topAnchor, constant: 1),
            contentBackground.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1),
            contentBackground.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.horizontalPadding),
            contentBackground.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.horizontalPadding),
            
            // Pin icon
            pinIcon.leadingAnchor.constraint(equalTo: contentBackground.leadingAnchor, constant: 8),
            pinIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
            pinIcon.widthAnchor.constraint(equalToConstant: 12),
            pinIcon.heightAnchor.constraint(equalToConstant: 12),
            
            // Text preview
            previewLabel.leadingAnchor.constraint(equalTo: contentBackground.leadingAnchor, constant: 10),
            previewLabel.trailingAnchor.constraint(equalTo: contentBackground.trailingAnchor, constant: -10),
            previewLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            // Image preview (same position as text)
            previewImageView.leadingAnchor.constraint(equalTo: contentBackground.leadingAnchor, constant: 10),
            previewImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            previewImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 60),
            previewImageView.widthAnchor.constraint(lessThanOrEqualToConstant: 100),
        ])
    }
    
    // MARK: - Hover tracking
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }
    
    override func mouseEntered(with event: NSEvent) {
        guard backgroundStyle != .emphasized else { return }
        isHovered = true
        updateAppearance(animated: true)
    }
    
    override func mouseExited(with event: NSEvent) {
        isHovered = false
        if backgroundStyle != .emphasized {
            updateAppearance(animated: true)
        }
    }
    
    // MARK: - Selection state
    
    override var backgroundStyle: NSView.BackgroundStyle {
        didSet {
            updateAppearance(animated: false)
        }
    }
    
    private func updateAppearance(animated: Bool) {
        let isSelected = backgroundStyle == .emphasized
        
        let updateBlock = {
            if isSelected {
                // Maccy-style: accent color at 0.8 opacity
                self.contentBackground.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.8).cgColor
                self.contentBackground.alphaValue = 1.0
                self.previewLabel.textColor = .white
            } else if self.isHovered {
                // Subtle hover - very slight background
                self.contentBackground.layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.06).cgColor
                self.contentBackground.alphaValue = 1.0
                self.previewLabel.textColor = .labelColor
            } else {
                self.contentBackground.alphaValue = 0
                self.previewLabel.textColor = .labelColor
            }
        }
        
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.1
                context.allowsImplicitAnimation = true
                updateBlock()
            }
        } else {
            updateBlock()
        }
    }
    
    // MARK: - Configure
    
    func configure(with item: ClipboardItem) {
        currentItem = item
        isHovered = false
        contentBackground.alphaValue = 0
        
        // Pin state
        pinIcon.isHidden = !item.isPinned
        
        switch item.type {
        case .text:
            previewImageView.isHidden = true
            previewLabel.isHidden = false
            
            // Clean up text - collapse whitespace, single line
            var text = (item.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            text = text.components(separatedBy: .newlines).joined(separator: " ")
            text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            
            previewLabel.stringValue = text
            
        case .image:
            previewImageView.isHidden = false
            previewLabel.isHidden = false
            previewImageView.image = item.image
            
            // Show dimensions as text
            if let img = item.image {
                let size = img.size
                previewLabel.stringValue = "Image (\(Int(size.width))×\(Int(size.height)))"
            } else {
                previewLabel.stringValue = "Image"
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        previewImageView.image = nil
        previewLabel.stringValue = ""
        pinIcon.isHidden = true
        isHovered = false
        contentBackground.alphaValue = 0
        currentItem = nil
    }
}
