import AppKit

// MARK: - Display Row Types

enum DisplayRow {
    case header(String)
    case divider
    case item(ClipboardItem)
}

class HistoryViewController: NSViewController {
    
    let searchField = NSTextField()
    private let scrollView = NSScrollView()
    private let tableView = NSTableView()
    private let emptyStateContainer = NSView()
    private let emptyStateIcon = NSImageView()
    private let emptyStateTitle = NSTextField(labelWithString: "")
    private let emptyStateSubtitle = NSTextField(labelWithString: "")
    
    private var displayRows: [DisplayRow] = []
    private var pinMenuItem: NSMenuItem?
    
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
        tableView.intercellSpacing = NSSize(width: 0, height: 2)
        tableView.rowHeight = 80
        tableView.usesAlternatingRowBackgroundColors = false
        
        // Right-click menu
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(NSMenuItem(title: "Paste", action: #selector(pasteSelected), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        pinMenuItem = NSMenuItem(title: "Pin", action: #selector(togglePinSelected), keyEquivalent: "p")
        menu.addItem(pinMenuItem!)
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
        scrollView.contentInsets = NSEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
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
            searchIcon.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            searchIcon.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            searchIcon.widthAnchor.constraint(equalToConstant: 20),
            searchIcon.heightAnchor.constraint(equalToConstant: 20),
            
            // Search Field
            searchField.centerYAnchor.constraint(equalTo: searchIcon.centerYAnchor),
            searchField.leadingAnchor.constraint(equalTo: searchIcon.trailingAnchor, constant: 8),
            searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            searchField.heightAnchor.constraint(equalToConstant: 28),
            
            // Divider
            divider.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 16),
            divider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            divider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            
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
        let allItems = ClipboardManager.shared.history
        let searchText = searchField.stringValue.lowercased()
        
        // Filter by search
        let filtered: [ClipboardItem]
        
        if searchText.isEmpty {
            filtered = allItems
        } else {
            filtered = allItems.filter { ($0.text ?? "").localizedCaseInsensitiveContains(searchText) }
        }
        
        // Build display rows with sections
        let pinnedItems = filtered.filter { $0.isPinned }
        let unpinnedItems = filtered.filter { !$0.isPinned }
        
        displayRows = []
        
        if !pinnedItems.isEmpty {
            displayRows.append(.header("Pinned"))
            displayRows.append(contentsOf: pinnedItems.map { .item($0) })
            
            if !unpinnedItems.isEmpty {
                displayRows.append(.divider)
            }
        }
        
        displayRows.append(contentsOf: unpinnedItems.map { .item($0) })
        
        // Update empty state
        let isEmpty = displayRows.isEmpty
        emptyStateContainer.isHidden = !isEmpty
        scrollView.isHidden = isEmpty
        
        if allItems.isEmpty {
            emptyStateIcon.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: nil)
            emptyStateTitle.stringValue = "No clipboard history"
            emptyStateSubtitle.stringValue = "Copy something to get started"
        } else {
            emptyStateIcon.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil)
            emptyStateTitle.stringValue = "No results"
            emptyStateSubtitle.stringValue = "Try a different search"
        }
        
        tableView.reloadData()
        
        // Auto-select first item row
        if tableView.selectedRow == -1 {
            if let firstItemIndex = displayRows.firstIndex(where: { if case .item = $0 { return true } else { return false } }) {
                tableView.selectRowIndexes(IndexSet(integer: firstItemIndex), byExtendingSelection: false)
            }
        }
    }
    
    // MARK: - Helper
    
    private func item(at row: Int) -> ClipboardItem? {
        guard row >= 0, row < displayRows.count else { return nil }
        if case .item(let item) = displayRows[row] {
            return item
        }
        return nil
    }
    
    // MARK: - Actions
    
    @objc private func onTableClick() {
        // Single click pastes immediately - use clickedRow since selection may not be set yet
        let row = tableView.clickedRow
        guard let item = item(at: row) else { return }
        pasteItem(item)
    }
    
    @objc private func onTableDoubleClick() {
        // Double click also pastes
        let row = tableView.clickedRow
        guard let item = item(at: row) else { return }
        pasteItem(item)
    }
    
    @objc private func pasteSelected() {
        confirmSelection()
    }
    
    @objc private func togglePinSelected() {
        let row = tableView.clickedRow >= 0 ? tableView.clickedRow : tableView.selectedRow
        guard let item = item(at: row) else { return }
        ClipboardManager.shared.togglePin(item)
    }
    
    @objc private func deleteSelected() {
        let row = tableView.clickedRow >= 0 ? tableView.clickedRow : tableView.selectedRow
        guard let item = item(at: row) else { return }
        ClipboardManager.shared.deleteItem(item)
    }
    
    func confirmSelection() {
        let row = tableView.selectedRow
        guard let item = item(at: row) else { return }
        pasteItem(item)
    }
    
    private func pasteItem(_ item: ClipboardItem) {
        // Copy to clipboard first
        ClipboardManager.shared.moveItemToTop(item)
        
        if let panel = view.window as? FloatingPanel {
            panel.hideWithAnimation {
                // Force app deactivation to ensure previous app gets focus
                NSApp.hide(nil)
                
                // Give time for the previous app to regain focus
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                    self?.synthesizePaste()
                }
            }
        }
    }
    
    private func synthesizePaste() {
        // Check for accessibility permissions quietly just before the action
        if !AXIsProcessTrusted() {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            AXIsProcessTrustedWithOptions(options as CFDictionary)
            return
        }

        let source = CGEventSource(stateID: .combinedSessionState)
        let kVK_ANSI_V: CGKeyCode = 0x09
        
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: kVK_ANSI_V, keyDown: true)
        keyDown?.flags = .maskCommand
        
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: kVK_ANSI_V, keyDown: false)
        keyUp?.flags = .maskCommand
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
    
    private func animateSelection(to row: Int) {
        guard row >= 0, row < displayRows.count else { return }
        // Only select if it's an item row
        if case .item = displayRows[row] {
            tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            tableView.scrollRowToVisible(row)
        }
    }
    
    // MARK: - Keyboard Shortcuts
    
    override func keyDown(with event: NSEvent) {
        // Handle ⌘P for pin/unpin
        if event.modifierFlags.contains(.command) {
            if let chars = event.charactersIgnoringModifiers?.lowercased(), chars == "p" {
                togglePinSelected()
                return
            }
            // ⌘ Backspace to delete
            if event.keyCode == 51 { // Backspace key
                deleteSelected()
                return
            }
        }
        super.keyDown(with: event)
    }
}

// MARK: - NSTextFieldDelegate

extension HistoryViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        refreshData()
    }
    
    private func nextItemRow(from row: Int, direction: Int) -> Int? {
        var next = row + direction
        while next >= 0 && next < displayRows.count {
            if case .item = displayRows[next] {
                return next
            }
            next += direction
        }
        return nil
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.moveDown(_:)) {
            let row = tableView.selectedRow
            if let next = nextItemRow(from: row, direction: 1) {
                animateSelection(to: next)
            }
            return true
        } else if commandSelector == #selector(NSResponder.moveUp(_:)) {
            let row = tableView.selectedRow
            if let next = nextItemRow(from: row, direction: -1) {
                animateSelection(to: next)
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
        return displayRows.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < displayRows.count else { return nil }
        
        switch displayRows[row] {
        case .header(let title):
            var cell = tableView.makeView(withIdentifier: SectionHeaderCell.identifier, owner: self) as? SectionHeaderCell
            if cell == nil {
                cell = SectionHeaderCell()
                cell?.identifier = SectionHeaderCell.identifier
            }
            cell?.configure(title: title)
            return cell
            
        case .divider:
            var cell = tableView.makeView(withIdentifier: SectionDividerCell.identifier, owner: self) as? SectionDividerCell
            if cell == nil {
                cell = SectionDividerCell()
                cell?.identifier = SectionDividerCell.identifier
            }
            return cell
            
        case .item(let item):
            var cell = tableView.makeView(withIdentifier: HistoryCell.identifier, owner: self) as? HistoryCell
            if cell == nil {
                cell = HistoryCell()
                cell?.identifier = HistoryCell.identifier
            }
            cell?.configure(with: item)
            
            // Wire up pin toggle callback
            cell?.onPinToggle = { [weak self] item in
                ClipboardManager.shared.togglePin(item)
                self?.refreshData()
            }
            return cell
        }
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        guard row < displayRows.count else { return 0 }
        
        switch displayRows[row] {
        case .header:
            return 28
        case .divider:
            return 16
        case .item(let item):
            return item.type == .image ? 92 : 80
        }
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return CleanRowView()
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        // Only allow selecting item rows
        guard row < displayRows.count else { return false }
        if case .item = displayRows[row] {
            return true
        }
        return false
    }
    
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

// MARK: - NSMenuDelegate

extension HistoryViewController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        // Update pin menu item text based on clicked row
        let row = tableView.clickedRow
        if let item = item(at: row) {
            pinMenuItem?.title = item.isPinned ? "Unpin" : "Pin"
        }
    }
}
