import AppKit

class AboutViewController: NSViewController {
    
    override func loadView() {
        self.view = NSView()
        self.view.wantsLayer = true
        self.view.frame = NSRect(x: 0, y: 0, width: 320, height: 280)
        
        setupUI()
    }
    
    private func setupUI() {
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .centerX
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40)
        ])
        
        // App Icon
        let iconImageView = NSImageView()
        iconImageView.image = NSApp.applicationIconImage
        iconImageView.imageScaling = .scaleProportionallyUpOrDown
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        iconImageView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        stackView.addArrangedSubview(iconImageView)
        
        // App Name
        let nameLabel = NSTextField(labelWithString: "Glassboard")
        nameLabel.font = .systemFont(ofSize: 22, weight: .bold)
        nameLabel.textColor = .labelColor
        stackView.addArrangedSubview(nameLabel)
        
        // Version
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let versionLabel = NSTextField(labelWithString: "Version \(version) (\(build))")
        versionLabel.font = .systemFont(ofSize: 13)
        versionLabel.textColor = .secondaryLabelColor
        stackView.addArrangedSubview(versionLabel)
        
        // Author
        let authorLabel = NSTextField(labelWithString: "Created by Luke Dust")
        authorLabel.font = .systemFont(ofSize: 13)
        authorLabel.textColor = .secondaryLabelColor
        stackView.addArrangedSubview(authorLabel)
        
        // Spacer
        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: 8).isActive = true
        stackView.addArrangedSubview(spacer)
        
        // Ko-fi Button
        let kofiButton = NSButton(title: "Buy me a Coffee ☕️", target: self, action: #selector(openSupportPage))
        kofiButton.bezelStyle = .rounded
        kofiButton.controlSize = .large
        stackView.addArrangedSubview(kofiButton)
        
        // Copyright
        let copyright = Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String ?? "© 2024 Luke Dust"
        let copyrightLabel = NSTextField(labelWithString: copyright)
        copyrightLabel.font = .systemFont(ofSize: 10)
        copyrightLabel.textColor = .tertiaryLabelColor
        
        // Add copyright at very bottom
        view.addSubview(copyrightLabel)
        copyrightLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            copyrightLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            copyrightLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
        ])
    }
    
    @objc private func openSupportPage() {
        if let url = URL(string: "https://ko-fi.com/luked7") {
            NSWorkspace.shared.open(url)
        }
    }
}
