import AppKit

class ClipboardManager {
    static let shared = ClipboardManager()
    
    private(set) var history: [ClipboardItem] = []
    private(set) var pinnedItems: [ClipboardItem] = []
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    
    // MVP: strict FIFO limit
    private let maxHistorySize = 200
    private let maxPinnedSize = 5
    
    // Callback for UI updates
    var onHistoryChanged: (() -> Void)?
    
    init() {
        self.lastChangeCount = -1 
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
        checkForChanges()
    }
    
    private func checkForChanges() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        
        if let newItem = extractCurrentItem() {
            add(item: newItem)
        }
    }
    
    private func extractCurrentItem() -> ClipboardItem? {
        // Try reading RTF first for rich text
        if let rtfData = pasteboard.data(forType: .rtf),
           let attrStr = NSAttributedString(rtf: rtfData, documentAttributes: nil) {
            let plainText = attrStr.string
            
            if plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return nil }
            
            // Deduplication
            if let top = history.first, top.text == plainText {
                return nil
            }
            
            print("[Clipboard] Captured RTF: \(plainText.prefix(20))...")
            return ClipboardItem(
                id: UUID(),
                type: .text,
                text: plainText,
                attributedText: attrStr,
                image: nil,
                date: Date()
            )
        }
        
        // Try reading plain strings
        if let str = pasteboard.string(forType: .string) {
            if str.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return nil }
            
            // Deduplication
            if let top = history.first, top.text == str {
                return nil
            }
            
            print("[Clipboard] Captured Text: \(str.prefix(20))...")
            return ClipboardItem(
                id: UUID(),
                type: .text,
                text: str,
                attributedText: nil,
                image: nil,
                date: Date()
            )
        } 
        
        // Try reading images
        if let img = NSImage(pasteboard: pasteboard) {
            print("[Clipboard] Captured Image: \(img.size)")
            return ClipboardItem(
                id: UUID(),
                type: .image,
                text: nil,
                attributedText: nil,
                image: img,
                date: Date()
            )
        }
        
        return nil
    }
    
    private func add(item: ClipboardItem) {
        history.insert(item, at: 0)
        
        if history.count > maxHistorySize {
            history.removeLast()
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.onHistoryChanged?()
        }
    }
    
    func moveItemToTop(_ item: ClipboardItem) {
        // Check in pinned items first
        if let index = pinnedItems.firstIndex(where: { $0.id == item.id }) {
            let pinnedItem = pinnedItems[index]
            copyToSystemPasteboard(pinnedItem)
            DispatchQueue.main.async { [weak self] in
                self?.onHistoryChanged?()
            }
            return
        }
        
        if let index = history.firstIndex(of: item) {
            history.remove(at: index)
            history.insert(item, at: 0)
            copyToSystemPasteboard(item)
            
            DispatchQueue.main.async { [weak self] in
                self?.onHistoryChanged?()
            }
        }
    }
    
    func togglePin(_ item: ClipboardItem) {
        if let index = pinnedItems.firstIndex(where: { $0.id == item.id }) {
            // Unpin - move back to history
            var unpinnedItem = pinnedItems.remove(at: index)
            unpinnedItem.isPinned = false
            history.insert(unpinnedItem, at: 0)
        } else if let index = history.firstIndex(where: { $0.id == item.id }) {
            // Pin - move to pinned
            guard pinnedItems.count < maxPinnedSize else { return }
            var pinnedItem = history.remove(at: index)
            pinnedItem.isPinned = true
            pinnedItems.append(pinnedItem)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.onHistoryChanged?()
        }
    }
    
    func deleteItem(_ item: ClipboardItem) {
        if let index = pinnedItems.firstIndex(where: { $0.id == item.id }) {
            pinnedItems.remove(at: index)
        } else if let index = history.firstIndex(where: { $0.id == item.id }) {
            history.remove(at: index)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.onHistoryChanged?()
        }
    }
    
    private func copyToSystemPasteboard(_ item: ClipboardItem) {
        pasteboard.clearContents()
        
        switch item.type {
        case .text:
            // Write RTF if available, plus plain text
            if let attrText = item.attributedText,
               let rtfData = try? attrText.data(from: NSRange(location: 0, length: attrText.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]) {
                pasteboard.setData(rtfData, forType: .rtf)
            }
            if let t = item.text {
                pasteboard.setString(t, forType: .string)
            }
        case .image:
            if let img = item.image {
                pasteboard.writeObjects([img])
            }
        }
        lastChangeCount = pasteboard.changeCount
    }
}
