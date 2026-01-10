import AppKit

class HistoryCell: NSTableCellView {
    static let identifier = NSUserInterfaceItemIdentifier("HistoryCell")
    
    private static let horizontalPadding: CGFloat = 10
    private static let cornerRadius: CGFloat = 12
    
    // Shared UI
    private let contentBackground = NSView()
    private let pinButton = NSButton()
    private let metadataLabel = NSTextField(labelWithString: "")
    
    // Text-specific UI
    private let previewLabel = NSTextField(labelWithString: "")
    
    // Image preview
    private let previewImageView = NSImageView()
    
    private var currentItem: ClipboardItem?
    
    // Callback for pin action
    var onPinToggle: ((ClipboardItem) -> Void)?
    
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
        
        // Pin button - subtle glass style, only appears on hover
        pinButton.translatesAutoresizingMaskIntoConstraints = false
        pinButton.bezelStyle = .accessoryBarAction
        pinButton.isBordered = false
        pinButton.image = NSImage(systemSymbolName: "pin", accessibilityDescription: "Pin")
        pinButton.contentTintColor = .secondaryLabelColor
        pinButton.imageScaling = .scaleProportionallyDown
        pinButton.target = self
        pinButton.action = #selector(pinButtonClicked)
        pinButton.alphaValue = 0
        addSubview(pinButton)
        
        // Main text preview - multiline for rich content
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        previewLabel.lineBreakMode = .byTruncatingTail
        previewLabel.maximumNumberOfLines = 3
        previewLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        previewLabel.textColor = .labelColor
        previewLabel.cell?.truncatesLastVisibleLine = true
        previewLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        previewLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        addSubview(previewLabel)
        
        // Metadata label - character count / image size + timestamp
        metadataLabel.translatesAutoresizingMaskIntoConstraints = false
        metadataLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        metadataLabel.textColor = .tertiaryLabelColor
        metadataLabel.lineBreakMode = .byTruncatingTail
        addSubview(metadataLabel)
        

        // Image preview - clean, no border
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        previewImageView.imageScaling = .scaleProportionallyUpOrDown
        previewImageView.wantsLayer = true
        previewImageView.layer?.cornerRadius = 6
        previewImageView.layer?.cornerCurve = .continuous
        previewImageView.layer?.masksToBounds = true
        addSubview(previewImageView)
        
        NSLayoutConstraint.activate([
            // Background fills cell with padding
            contentBackground.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            contentBackground.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            contentBackground.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.horizontalPadding),
            contentBackground.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.horizontalPadding),
            
            // Pin button - top right corner
            pinButton.topAnchor.constraint(equalTo: contentBackground.topAnchor, constant: 10),
            pinButton.trailingAnchor.constraint(equalTo: contentBackground.trailingAnchor, constant: -10),
            pinButton.widthAnchor.constraint(equalToConstant: 24),
            pinButton.heightAnchor.constraint(equalToConstant: 24),
            
            // Text preview - top area, always starts at leading edge
            previewLabel.topAnchor.constraint(equalTo: contentBackground.topAnchor, constant: 12),
            previewLabel.leadingAnchor.constraint(equalTo: contentBackground.leadingAnchor, constant: 14),
            previewLabel.trailingAnchor.constraint(equalTo: pinButton.leadingAnchor, constant: -8),
            
            // Metadata - bottom right, always visible
            metadataLabel.bottomAnchor.constraint(equalTo: contentBackground.bottomAnchor, constant: -10),
            metadataLabel.trailingAnchor.constraint(equalTo: contentBackground.trailingAnchor, constant: -14),
            
            // Image view - smaller size to leave room for metadata
            previewImageView.topAnchor.constraint(equalTo: contentBackground.topAnchor, constant: 10),
            previewImageView.leadingAnchor.constraint(equalTo: contentBackground.leadingAnchor, constant: 14),
            previewImageView.widthAnchor.constraint(lessThanOrEqualToConstant: 100),
            previewImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 48),
        ])
    }
    
    // MARK: - Pin Action
    
    @objc private func pinButtonClicked() {
        guard let item = currentItem else { return }
        onPinToggle?(item)
    }
    
    // MARK: - Selection state
    
    override var backgroundStyle: NSView.BackgroundStyle {
        didSet {
            updateAppearance(animated: false)
        }
    }
    
    private func updateAppearance(animated: Bool) {
        let isSelected = backgroundStyle == .emphasized
        let isPinned = currentItem?.isPinned ?? false
        
        let updateBlock = {
            // Pin button - only show when selected
            if isSelected {
                self.pinButton.alphaValue = 1.0
                self.pinButton.image = NSImage(systemSymbolName: isPinned ? "pin.slash" : "pin", accessibilityDescription: isPinned ? "Unpin" : "Pin")
                self.pinButton.contentTintColor = NSColor.white.withAlphaComponent(0.8)
            } else {
                self.pinButton.alphaValue = 0
            }
            
            if isSelected {
                self.contentBackground.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.85).cgColor
                self.contentBackground.alphaValue = 1.0
                self.previewLabel.textColor = .white
                self.metadataLabel.textColor = NSColor.white.withAlphaComponent(0.7)
            } else {
                self.contentBackground.alphaValue = 0
                self.previewLabel.textColor = .labelColor
                self.metadataLabel.textColor = .tertiaryLabelColor
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
        contentBackground.alphaValue = 0
        
        // Format relative date
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let timeAgo = formatter.localizedString(for: item.date, relativeTo: Date())
        
        switch item.type {
        case .text:
            previewImageView.isHidden = true
            previewLabel.isHidden = false
            
            let text = item.text ?? ""
            
            // Clean up text for preview - preserve some newlines for context
            var preview = text.trimmingCharacters(in: .whitespacesAndNewlines)
            // Replace multiple newlines with single, collapse excessive whitespace
            preview = preview.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
            preview = preview.replacingOccurrences(of: "[ \t]+", with: " ", options: .regularExpression)
            
            previewLabel.stringValue = preview
            
            // Metadata: character count + time
            let charCount = text.count
            let charDisplay = charCount >= 1000 ? "\(charCount / 1000)k" : "\(charCount)"
            metadataLabel.stringValue = "\(charDisplay) chars · \(timeAgo)"
            
        case .image:
            previewImageView.isHidden = false
            previewLabel.isHidden = true
            previewImageView.image = item.image
            
            // Metadata: image dimensions + file size + time
            if let img = item.image {
                let size = img.size
                var metaParts = ["\(Int(size.width))×\(Int(size.height))px"]
                
                // Calculate file size from image data
                if let tiffData = img.tiffRepresentation,
                   let bitmapRep = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                    let bytes = pngData.count
                    if bytes >= 1_000_000 {
                        metaParts.append(String(format: "%.1fMB", Double(bytes) / 1_000_000))
                    } else if bytes >= 1000 {
                        metaParts.append("\(bytes / 1000)KB")
                    } else {
                        metaParts.append("\(bytes)B")
                    }
                }
                
                metaParts.append(timeAgo)
                metadataLabel.stringValue = metaParts.joined(separator: " · ")
            } else {
                metadataLabel.stringValue = "Image · \(timeAgo)"
            }
        }
        
        // Ensure metadata is always visible
        metadataLabel.isHidden = false
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        previewImageView.image = nil
        previewImageView.isHidden = true
        previewLabel.stringValue = ""
        metadataLabel.stringValue = ""
        pinButton.alphaValue = 0
        previewLabel.isHidden = false
        contentBackground.alphaValue = 0
        currentItem = nil
        onPinToggle = nil
    }
}

// MARK: - Section Header Cell

class SectionHeaderCell: NSTableCellView {
    static let identifier = NSUserInterfaceItemIdentifier("SectionHeaderCell")
    
    private let titleLabel = NSTextField(labelWithString: "")
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        titleLabel.textColor = .secondaryLabelColor
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
    }
    
    func configure(title: String) {
        titleLabel.stringValue = title.uppercased()
    }
}

// MARK: - Section Divider Cell

class SectionDividerCell: NSTableCellView {
    static let identifier = NSUserInterfaceItemIdentifier("SectionDividerCell")
    
    private let dividerLine = NSBox()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        dividerLine.translatesAutoresizingMaskIntoConstraints = false
        dividerLine.boxType = .separator
        addSubview(dividerLine)
        
        NSLayoutConstraint.activate([
            dividerLine.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            dividerLine.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            dividerLine.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}
