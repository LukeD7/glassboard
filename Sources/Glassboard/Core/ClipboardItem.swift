import AppKit

enum ClipboardContentType: String, Codable, Hashable {
    case text
    case image
}

struct ClipboardItem: Identifiable, Hashable, Codable {
    let id: UUID
    let type: ClipboardContentType
    let text: String?
    let attributedText: NSAttributedString?
    let image: NSImage?
    let date: Date
    var isPinned: Bool
    
    // For images, we store a reference to the file on disk
    var imageFileName: String?
    
    init(id: UUID, type: ClipboardContentType, text: String?, attributedText: NSAttributedString? = nil, image: NSImage?, date: Date, isPinned: Bool = false, imageFileName: String? = nil) {
        self.id = id
        self.type = type
        self.text = text
        self.attributedText = attributedText
        self.image = image
        self.date = date
        self.isPinned = isPinned
        self.imageFileName = imageFileName
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id, type, text, attributedTextRTF, date, isPinned, imageFileName
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encode(date, forKey: .date)
        try container.encode(isPinned, forKey: .isPinned)
        try container.encodeIfPresent(imageFileName, forKey: .imageFileName)
        
        // Encode attributed text as RTF data
        if let attrText = attributedText {
            let rtfData = try? attrText.data(
                from: NSRange(location: 0, length: attrText.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
            )
            try container.encodeIfPresent(rtfData, forKey: .attributedTextRTF)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(ClipboardContentType.self, forKey: .type)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        date = try container.decode(Date.self, forKey: .date)
        isPinned = try container.decode(Bool.self, forKey: .isPinned)
        imageFileName = try container.decodeIfPresent(String.self, forKey: .imageFileName)
        
        // Decode RTF data back to attributed string
        if let rtfData = try container.decodeIfPresent(Data.self, forKey: .attributedTextRTF) {
            attributedText = NSAttributedString(rtf: rtfData, documentAttributes: nil)
        } else {
            attributedText = nil
        }
        
        // Image will be loaded separately from disk
        image = nil
    }
}
