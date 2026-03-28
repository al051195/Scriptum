import Foundation
import SwiftUI

// MARK: - Note Model

struct Note: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var title: String
    var body: String
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()
    var tags: [String] = []
    var isPinned: Bool = false
    var accentColor: NoteAccent = .gold
    var wordCount: Int { body.split(separator: " ").count }
    var preview: String { String(body.prefix(120)).trimmingCharacters(in: .whitespacesAndNewlines) }

    static func empty() -> Note {
        Note(title: "", body: "")
    }
}

// MARK: - Note Accent

enum NoteAccent: String, Codable, CaseIterable {
    case gold, teal, rose, sky, lavender

    var color: Color {
        switch self {
        case .gold:     return Color(hex: "F5C842")
        case .teal:     return Color(hex: "2DD4BF")
        case .rose:     return Color(hex: "FB7185")
        case .sky:      return Color(hex: "7DD3FC")
        case .lavender: return Color(hex: "C4B5FD")
        }
    }

    var dimColor: Color {
        color.opacity(0.15)
    }

    var label: String { rawValue.capitalized }
}

// MARK: - Sort Option

enum SortOption: String, CaseIterable {
    case modified = "Recently Modified"
    case created  = "Date Created"
    case title    = "Title A–Z"
    case wordCount = "Word Count"
}

// MARK: - Tag

typealias Tag = String

