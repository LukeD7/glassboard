import AppKit

enum ClipboardContentType: Hashable {
    case text
    case image
}

struct ClipboardItem: Identifiable, Hashable {
    let id: UUID
    let type: ClipboardContentType
    let text: String?
    let attributedText: NSAttributedString?
    let image: NSImage?
    let date: Date
    var isPinned: Bool
    
    init(id: UUID, type: ClipboardContentType, text: String?, attributedText: NSAttributedString? = nil, image: NSImage?, date: Date, isPinned: Bool = false) {
        self.id = id
        self.type = type
        self.text = text
        self.attributedText = attributedText
        self.image = image
        self.date = date
        self.isPinned = isPinned
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        return lhs.id == rhs.id
    }
}
