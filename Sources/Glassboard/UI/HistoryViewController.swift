import AppKit

class HistoryViewController: NSViewController {
    
    let searchField = NSTextField()
    private let scrollView = NSScrollView()
    private let tableView = NSTableView()
    private let emptyStateContainer = NSView()
    private let emptyStateIcon = NSImageView()
    private let emptyStateTitle = NSTextField(labelWithString: "")
    private let emptyStateSubtitle = NSTextField(labelWithString: "")
    
    private var displayItems: [ClipboardItem] = []
    private var pinnedCount: Int = 0
    
    override func loadView() {
        self.view = NSView()
        self.view.wantsLayer = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupUI()
        setupBindings()
        refreshData()
    }
    
    private func setupBackground() {
        // Liquid glass effect for macOS 26+, fallback to popover material
        if #available(macOS 26.0, *) {
            let glassView = NSGlassEffectView()
            glassView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(glassView)
            
            NSLayoutConstraint.activate([
                glassView.topAnchor.constraint(equalTo: view.topAnchor),
                glassView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                glassView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                glassView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        } else {
            let visualEffect = NSVisualEffectView()
            visualEffect.material = .popover
            visualEffect.state = .active
            visualEffect.blendingMode = .behindWindow
            visualEffect.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(visualEffect)
            
            NSLayoutConstraint.activate([
                visualEffect.topAnchor.constraint(equalTo: view.topAnchor),
                visualEffect.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                visualEffect.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                visualEffect.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.view.window?.makeFirstResponder(self?.searchField)
        }
        searchField.stringValue = ""
        refreshData()
    }
    
    private func setupUI() {
        // ═══════════════════════════════════════════════════════════════
        // SEARCH FIELD - Minimal, Spotlight-inspired
        // ═══════════════════════════════════════════════════════════════
        
        // Search icon
        let searchIcon = NSImageView()
        searchIcon.translatesAutoresizingMaskIntoConstraints = false
        searchIcon.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: "Search")
        searchIcon.contentTintColor = .tertiaryLabelColor
        searchIcon.imageScaling = .scaleProportionallyDown
        view.addSubview(searchIcon)
        
        // Search field - plain, no container
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.placeholderString = "Search"
        searchField.delegate = self
        searchField.focusRingType = .none
        searchField.font = NSFont.systemFont(ofSize: 20, weight: .light)
        searchField.isBezeled = false
        searchField.drawsBackground = false
        searchField.textColor = .labelColor
        
        let placeholderStr = NSAttributedString(
            string: "Search",
            attributes: [
                .foregroundColor: NSColor.placeholderTextColor,
                .font: NSFont.systemFont(ofSize: 20, weight: .light)
            ]
        )
        searchField.placeholderAttributedString = placeholderStr
        view.addSubview(searchField)
        
        // Divider
        let divider = NSBox()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.boxType = .separator
        view.addSubview(divider)
        
        // ═══════════════════════════════════════════════════════════════
        // TABLE VIEW
        // ═══════════════════════════════════════════════════════════════
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.headerView = nil
        tableView.backgroundColor = .clear
        tableView.style = .plain
        tableView.selectionHighlightStyle = .none
        tableView.action = #selector(onTableClick)
        tableView.doubleAction = #selector(onTableDoubleClick)
        tableView.target = self
        tableView.intercellSpacing = NSSize(width: 0, height: 0)
        tableView.rowHeight = 36
        tableView.usesAlternatingRowBackgroundColors = false
        
        // Right-click menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Paste", action: #selector(pasteSelected), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Pin", action: #selector(togglePinSelected), keyEquivalent: "p"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Delete", action: #selector(deleteSelected), keyEquivalent: ""))
        tableView.menu = menu
        
        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("MainCol"))
        col.resizingMask = .autoresizingMask
        tableView.addTableColumn(col)
        
        scrollView.documentView = tableView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.scrollerStyle = .overlay
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets = NSEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        view.addSubview(scrollView)
        
        // ═══════════════════════════════════════════════════════════════
        // EMPTY STATE
        // ═══════════════════════════════════════════════════════════════
        
        emptyStateContainer.translatesAutoresizingMaskIntoConstraints = false
        emptyStateContainer.isHidden = true
        view.addSubview(emptyStateContainer)
        
        emptyStateIcon.translatesAutoresizingMaskIntoConstraints = false
        emptyStateIcon.imageScaling = .scaleProportionallyDown
        emptyStateIcon.contentTintColor = .tertiaryLabelColor
        emptyStateContainer.addSubview(emptyStateIcon)
        
        emptyStateTitle.translatesAutoresizingMaskIntoConstraints = false
        emptyStateTitle.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        emptyStateTitle.textColor = .secondaryLabelColor
        emptyStateTitle.alignment = .center
        emptyStateContainer.addSubview(emptyStateTitle)
        
        emptyStateSubtitle.translatesAutoresizingMaskIntoConstraints = false
        emptyStateSubtitle.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        emptyStateSubtitle.textColor = .tertiaryLabelColor
        emptyStateSubtitle.alignment = .center
        emptyStateContainer.addSubview(emptyStateSubtitle)
        
        // ═══════════════════════════════════════════════════════════════
        // LAYOUT
        // ═══════════════════════════════════════════════════════════════
        
        NSLayoutConstraint.activate([
            // Search Icon
            searchIcon.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            searchIcon.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchIcon.widthAnchor.constraint(equalToConstant: 20),
            searchIcon.heightAnchor.constraint(equalToConstant: 20),
            
            // Search Field
            searchField.centerYAnchor.constraint(equalTo: searchIcon.centerYAnchor),
            searchField.leadingAnchor.constraint(equalTo: searchIcon.trailingAnchor, constant: 8),
            searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchField.heightAnchor.constraint(equalToConstant: 28),
            
            // Divider
            divider.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 12),
            divider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            divider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 6),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6),
            
            // Empty State
            emptyStateContainer.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            emptyStateContainer.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            
            emptyStateIcon.topAnchor.constraint(equalTo: emptyStateContainer.topAnchor),
            emptyStateIcon.centerXAnchor.constraint(equalTo: emptyStateContainer.centerXAnchor),
            emptyStateIcon.widthAnchor.constraint(equalToConstant: 40),
            emptyStateIcon.heightAnchor.constraint(equalToConstant: 40),
            
            emptyStateTitle.topAnchor.constraint(equalTo: emptyStateIcon.bottomAnchor, constant: 12),
            emptyStateTitle.centerXAnchor.constraint(equalTo: emptyStateContainer.centerXAnchor),
            
            emptyStateSubtitle.topAnchor.constraint(equalTo: emptyStateTitle.bottomAnchor, constant: 4),
            emptyStateSubtitle.centerXAnchor.constraint(equalTo: emptyStateContainer.centerXAnchor),
            emptyStateSubtitle.bottomAnchor.constraint(equalTo: emptyStateContainer.bottomAnchor)
        ])
    }
    
    private func setupBindings() {
        ClipboardManager.shared.onHistoryChanged = { [weak self] in
            self?.refreshData()
        }
    }
    
    func refreshData() {
        let pinned = ClipboardManager.shared.pinnedItems
        let all = ClipboardManager.shared.history
        let searchText = searchField.stringValue.lowercased()
        
        // Filter by search
        let filteredPinned: [ClipboardItem]
        let filteredHistory: [ClipboardItem]
        
        if searchText.isEmpty {
            filteredPinned = pinned
            filteredHistory = all
        } else {
            filteredPinned = pinned.filter { ($0.text ?? "").localizedCaseInsensitiveContains(searchText) }
            filteredHistory = all.filter { ($0.text ?? "").localizedCaseInsensitiveContains(searchText) }
        }
        
        // Combine: pinned first, then history
        pinnedCount = filteredPinned.count
        displayItems = filteredPinned + filteredHistory
        
        // Update empty state
        let isEmpty = displayItems.isEmpty
        emptyStateContainer.isHidden = !isEmpty
        scrollView.isHidden = isEmpty
        
        if pinned.isEmpty && all.isEmpty {
            emptyStateIcon.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: nil)
            emptyStateTitle.stringValue = "No clipboard history"
            emptyStateSubtitle.stringValue = "Copy something to get started"
        } else {
            emptyStateIcon.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil)
            emptyStateTitle.stringValue = "No results"
            emptyStateSubtitle.stringValue = "Try a different search"
        }
        
        tableView.reloadData()
        
        // Auto-select first row
        if tableView.selectedRow == -1 && !displayItems.isEmpty {
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
    }
    
    // MARK: - Actions
    
    @objc private func onTableClick() {
        // Single click just selects
    }
    
    @objc private func onTableDoubleClick() {
        confirmSelection()
    }
    
    @objc private func pasteSelected() {
        confirmSelection()
    }
    
    @objc private func togglePinSelected() {
        let row = tableView.clickedRow >= 0 ? tableView.clickedRow : tableView.selectedRow
        guard row >= 0, row < displayItems.count else { return }
        ClipboardManager.shared.togglePin(displayItems[row])
    }
    
    @objc private func deleteSelected() {
        let row = tableView.clickedRow >= 0 ? tableView.clickedRow : tableView.selectedRow
        guard row >= 0, row < displayItems.count else { return }
        ClipboardManager.shared.deleteItem(displayItems[row])
    }
    
    func confirmSelection() {
        let row = tableView.selectedRow
        guard row >= 0, row < displayItems.count else { return }
        let item = displayItems[row]
        
        ClipboardManager.shared.moveItemToTop(item)
        
        if let panel = view.window as? FloatingPanel {
            panel.hideWithAnimation { [weak self] in
                NSApp.hide(nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    self?.synthesizePaste()
                }
            }
        }
    }
    
    private func synthesizePaste() {
        let source = CGEventSource(stateID: .hidSystemState)
        let kVK_ANSI_V = 0x09
        
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        keyDown?.flags = .maskCommand
        
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        keyUp?.flags = .maskCommand
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
    
    private func animateSelection(to row: Int) {
        guard row >= 0, row < displayItems.count else { return }
        tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        tableView.scrollRowToVisible(row)
    }
}

// MARK: - NSTextFieldDelegate

extension HistoryViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        refreshData()
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.moveDown(_:)) {
            let row = tableView.selectedRow
            if row < displayItems.count - 1 {
                animateSelection(to: row + 1)
            }
            return true
        } else if commandSelector == #selector(NSResponder.moveUp(_:)) {
            let row = tableView.selectedRow
            if row > 0 {
                animateSelection(to: row - 1)
            }
            return true
        } else if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            confirmSelection()
            return true
        } else if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            if let panel = view.window as? FloatingPanel {
                panel.hideWithAnimation {
                    NSApp.hide(nil)
                }
            }
            return true
        }
        return false
    }
}

// MARK: - NSTableViewDataSource & Delegate

extension HistoryViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return displayItems.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cell = tableView.makeView(withIdentifier: HistoryCell.identifier, owner: self) as? HistoryCell
        if cell == nil {
            cell = HistoryCell()
            cell?.identifier = HistoryCell.identifier
        }
        
        // Pass both item and index for keyboard shortcut display
        cell?.configure(with: displayItems[row])
        return cell
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let item = displayItems[row]
        return item.type == .image ? 72 : 36
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return CleanRowView()
    }
    
    // Section headers for pinned items
    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        return false
    }
}

// MARK: - Clean Row View

class CleanRowView: NSTableRowView {
    override func drawSelection(in dirtyRect: NSRect) {
        // Cell handles its own selection appearance
    }
    
    override var isEmphasized: Bool {
        get { true }
        set { }
    }
}
