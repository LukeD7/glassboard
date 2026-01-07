import AppKit

class ClipboardManager {
    static let shared = ClipboardManager()
    
    private(set) var history: [ClipboardItem] = []
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    
    // MVP: strict FIFO limit
    private let maxHistorySize = 200
    private let maxPinnedSize = 10
    
    // Computed property for pinned items (no separate storage)
    var pinnedItems: [ClipboardItem] {
        history.filter { $0.isPinned }
    }
    
    // Computed property for unpinned items
    var unpinnedItems: [ClipboardItem] {
        history.filter { !$0.isPinned }
    }
    
    // Callback for UI updates
    var onHistoryChanged: (() -> Void)?
    
    // MARK: - Persistence
    
    private static var storageDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let glassboard = appSupport.appendingPathComponent("Glassboard", isDirectory: true)
        try? FileManager.default.createDirectory(at: glassboard, withIntermediateDirectories: true)
        return glassboard
    }
    
    private static var historyFile: URL {
        storageDirectory.appendingPathComponent("history.json")
    }
    
    private static var imagesDirectory: URL {
        let dir = storageDirectory.appendingPathComponent("images", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    init() {
        self.lastChangeCount = -1
        loadFromDisk()
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
            
            // Deduplication: check against all existing items
            if history.contains(where: { $0.text == plainText }) {
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
            
            // Deduplication: check against all existing items
            if history.contains(where: { $0.text == str }) {
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
        var itemToAdd = item
        
        // Save image to disk if needed
        if item.type == .image, let img = item.image {
            let fileName = "\(item.id.uuidString).png"
            let fileURL = Self.imagesDirectory.appendingPathComponent(fileName)
            
            if let tiffData = img.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                try? pngData.write(to: fileURL)
                itemToAdd = ClipboardItem(
                    id: item.id,
                    type: item.type,
                    text: item.text,
                    attributedText: item.attributedText,
                    image: img,
                    date: item.date,
                    isPinned: item.isPinned,
                    imageFileName: fileName
                )
            }
        }
        
        // Insert after pinned items (new items go to top of unpinned section)
        let insertIndex = pinnedItems.count
        history.insert(itemToAdd, at: insertIndex)
        
        // Enforce history size limit (remove oldest unpinned items first)
        while history.count > maxHistorySize {
            // Find last unpinned item to remove
            if let lastUnpinnedIndex = history.lastIndex(where: { !$0.isPinned }) {
                let removed = history.remove(at: lastUnpinnedIndex)
                // Clean up image file if needed
                if removed.type == .image, let fileName = removed.imageFileName {
                    let fileURL = Self.imagesDirectory.appendingPathComponent(fileName)
                    try? FileManager.default.removeItem(at: fileURL)
                }
            } else {
                break // All items are pinned, can't remove
            }
        }
        
        saveToDisk()
        
        DispatchQueue.main.async { [weak self] in
            self?.onHistoryChanged?()
        }
    }
    
    func moveItemToTop(_ item: ClipboardItem) {
        if let index = history.firstIndex(where: { $0.id == item.id }) {
            let movedItem = history.remove(at: index)
            // If pinned, keep at front of pinned section, otherwise front of unpinned
            if movedItem.isPinned {
                // Already at logical top for pinned items
                history.insert(movedItem, at: 0)
            } else {
                // Insert after all pinned items
                let insertIndex = pinnedItems.count
                history.insert(movedItem, at: insertIndex)
            }
            copyToSystemPasteboard(movedItem)
            saveToDisk()
            
            DispatchQueue.main.async { [weak self] in
                self?.onHistoryChanged?()
            }
        }
    }
    
    func togglePin(_ item: ClipboardItem) {
        guard let index = history.firstIndex(where: { $0.id == item.id }) else { return }
        
        // Check pin limit
        if !history[index].isPinned && pinnedItems.count >= maxPinnedSize {
            return
        }
        
        // Toggle the pin state
        history[index].isPinned.toggle()
        
        // Reorder: pinned items first, then unpinned by date
        let pinned = history.filter { $0.isPinned }.sorted { $0.date > $1.date }
        let unpinned = history.filter { !$0.isPinned }.sorted { $0.date > $1.date }
        history = pinned + unpinned
        
        saveToDisk()
        
        DispatchQueue.main.async { [weak self] in
            self?.onHistoryChanged?()
        }
    }
    
    func deleteItem(_ item: ClipboardItem) {
        guard let index = history.firstIndex(where: { $0.id == item.id }) else { return }
        
        let removed = history.remove(at: index)
        
        // Clean up image file
        if removed.type == .image, let fileName = removed.imageFileName {
            let fileURL = Self.imagesDirectory.appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        saveToDisk()
        
        DispatchQueue.main.async { [weak self] in
            self?.onHistoryChanged?()
        }
    }
    
    // MARK: - Persistence
    
    private func saveToDisk() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        if let historyData = try? encoder.encode(history) {
            try? historyData.write(to: Self.historyFile)
        }
    }
    
    private func loadFromDisk() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Load history (includes both pinned and unpinned)
        if let data = try? Data(contentsOf: Self.historyFile),
           var items = try? decoder.decode([ClipboardItem].self, from: data) {
            // Load images from disk
            items = items.map { loadImage(for: $0) }
            
            // Deduplicate by text content (keep first occurrence - most recent)
            var seenTexts = Set<String>()
            var seenIds = Set<UUID>()
            items = items.filter { item in
                // Always dedupe by ID
                guard !seenIds.contains(item.id) else { return false }
                seenIds.insert(item.id)
                
                // For text items, also dedupe by content
                if let text = item.text {
                    guard !seenTexts.contains(text) else { return false }
                    seenTexts.insert(text)
                }
                return true
            }
            
            // Ensure pinned items are first
            let pinned = items.filter { $0.isPinned }
            let unpinned = items.filter { !$0.isPinned }
            history = pinned + unpinned
        }
        
        // Migration: load old pinned.json if it exists and merge
        let oldPinnedFile = Self.storageDirectory.appendingPathComponent("pinned.json")
        if let data = try? Data(contentsOf: oldPinnedFile),
           var oldPinned = try? decoder.decode([ClipboardItem].self, from: data) {
            oldPinned = oldPinned.map { loadImage(for: $0) }
            // Add old pinned items that aren't already in history
            for var item in oldPinned {
                if !history.contains(where: { $0.id == item.id || $0.text == item.text }) {
                    item.isPinned = true
                    history.insert(item, at: 0)
                }
            }
            // Delete old file after migration
            try? FileManager.default.removeItem(at: oldPinnedFile)
            saveToDisk()
        }
        
        // Clean up orphaned image files
        cleanupOrphanedImages()
        
        print("[ClipboardManager] Loaded \(history.count) items (\(pinnedItems.count) pinned)")
    }
    
    private func cleanupOrphanedImages() {
        let validFileNames = Set(history.compactMap { $0.imageFileName })
        
        if let files = try? FileManager.default.contentsOfDirectory(at: Self.imagesDirectory, includingPropertiesForKeys: nil) {
            for file in files {
                let fileName = file.lastPathComponent
                if !validFileNames.contains(fileName) {
                    try? FileManager.default.removeItem(at: file)
                    print("[ClipboardManager] Cleaned up orphaned image: \(fileName)")
                }
            }
        }
    }

    
    private func loadImage(for item: ClipboardItem) -> ClipboardItem {
        guard item.type == .image, let fileName = item.imageFileName else { return item }
        
        let fileURL = Self.imagesDirectory.appendingPathComponent(fileName)
        guard let image = NSImage(contentsOf: fileURL) else { return item }
        
        return ClipboardItem(
            id: item.id,
            type: item.type,
            text: item.text,
            attributedText: item.attributedText,
            image: image,
            date: item.date,
            isPinned: item.isPinned,
            imageFileName: item.imageFileName
        )
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
    
    func clearHistory() {
        // Delete all image files
        for item in history where item.type == .image {
            if let fileName = item.imageFileName {
                let fileURL = Self.imagesDirectory.appendingPathComponent(fileName)
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
        
        // Clear all items from history
        history.removeAll()
        
        // Save empty state to disk
        saveToDisk()
        
        print("[ClipboardManager] History cleared")
        
        DispatchQueue.main.async { [weak self] in
            self?.onHistoryChanged?()
        }
    }
}
