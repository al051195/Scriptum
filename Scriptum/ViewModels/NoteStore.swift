import Foundation
import Combine
import SwiftUI

@MainActor
final class NoteStore: ObservableObject {
    @Published var notes: [Note] = []
    @Published var searchQuery: String = ""
    @Published var selectedTag: String? = nil
    @Published var sortOption: SortOption = .modified

    private let saveKey = "folio.notes.v1"

    // MARK: - Computed

    var allTags: [String] {
        Array(Set(notes.flatMap { $0.tags })).sorted()
    }

    var pinnedNotes: [Note] {
        filtered(notes.filter { $0.isPinned })
    }

    var unpinnedNotes: [Note] {
        filtered(notes.filter { !$0.isPinned })
    }

    private func filtered(_ source: [Note]) -> [Note] {
        var result = source

        if !searchQuery.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchQuery) ||
                $0.body.localizedCaseInsensitiveContains(searchQuery) ||
                $0.tags.contains { $0.localizedCaseInsensitiveContains(searchQuery) }
            }
        }

        if let tag = selectedTag {
            result = result.filter { $0.tags.contains(tag) }
        }

        switch sortOption {
        case .modified:   result.sort { $0.modifiedAt > $1.modifiedAt }
        case .created:    result.sort { $0.createdAt > $1.createdAt }
        case .title:      result.sort { $0.title.lowercased() < $1.title.lowercased() }
        case .wordCount:  result.sort { $0.wordCount > $1.wordCount }
        }

        return result
    }

    // MARK: - CRUD

    func add(_ note: Note) {
        notes.insert(note, at: 0)
        save()
    }

    func update(_ note: Note) {
        guard let idx = notes.firstIndex(where: { $0.id == note.id }) else { return }
        var updated = note
        updated.modifiedAt = Date()
        notes[idx] = updated
        save()
    }

    func delete(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        save()
    }

    func delete(at offsets: IndexSet, in source: [Note]) {
        let ids = offsets.map { source[$0].id }
        notes.removeAll { ids.contains($0.id) }
        save()
    }

    func togglePin(_ note: Note) {
        guard let idx = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[idx].isPinned.toggle()
        save()
    }

    func duplicate(_ note: Note) {
        var copy = note
        copy.id = UUID()
        copy.title = note.title.isEmpty ? "Copy" : "\(note.title) Copy"
        copy.createdAt = Date()
        copy.modifiedAt = Date()
        copy.isPinned = false
        notes.insert(copy, at: 0)
        save()
    }

    // MARK: - Persistence

    func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([Note].self, from: data)
        else {
            notes = Note.sampleNotes()
            return
        }
        notes = decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(notes) else { return }
        UserDefaults.standard.set(data, forKey: saveKey)
    }
}

// MARK: - Sample Data

extension Note {
    static func sampleNotes() -> [Note] {
        [
            Note(
                title: "Welcome to Folio",
                body: "Folio is your minimal, beautiful notebook. Tap any note to edit it, swipe to delete, and use the + button to create a new one.\n\nAll your notes are stored privately on your device.",
                tags: ["welcome", "guide"],
                isPinned: true,
                accentColor: .gold
            ),
            Note(
                title: "Design Principles",
                body: "Great design is invisible. It gets out of the way and lets the content breathe.\n\n• Clarity above all\n• Motion with purpose\n• Depth through contrast",
                tags: ["design", "ideas"],
                accentColor: .teal
            ),
            Note(
                title: "Meeting Notes",
                body: "Discussed the Q2 roadmap. Key points:\n- Ship the new editor by end of month\n- Conduct user research sessions\n- Review accessibility audit",
                tags: ["work"],
                accentColor: .sky
            ),
            Note(
                title: "Book List",
                body: "Reading queue:\n1. The Design of Everyday Things\n2. A Pattern Language\n3. The Elements of Typographic Style\n4. Thinking, Fast and Slow",
                tags: ["books", "personal"],
                accentColor: .lavender
            ),
            Note(
                title: "Recipe — Risotto",
                body: "Ingredients: Arborio rice, parmesan, white wine, shallots, vegetable stock, butter.\n\nToast the rice dry before adding wine. Add stock ladle by ladle, stirring constantly. Finish with cold butter off heat.",
                tags: ["food"],
                accentColor: .rose
            )
        ]
    }
}
