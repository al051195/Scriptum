import SwiftUI

struct NewNoteSheet: View {
    let onCreate: (Note) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var aiService: AIService

    @State private var title: String = ""
    @State private var noteBody: String = ""
    @State private var selectedAccent: NoteAccent = .gold
    @State private var tags: String = ""
    @FocusState private var bodyFocused: Bool

    var parsedTags: [String] {
        tags.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        ZStack {
            MeshBackgroundView().ignoresSafeArea()

            VStack(spacing: 0) {
                // Sheet handle + header
                SheetHeader(
                    title: "New Note",
                    accent: selectedAccent.color
                ) {
                    dismiss()
                } onSave: {
                    save()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title field
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Title", systemImage: "textformat")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(ThemeManager.t3)
                                .kerning(1)

                            TextField("Give it a name...", text: $title)
                                .font(.system(size: 22, weight: .bold, design: .serif))
                                .foregroundStyle(ThemeManager.t1)
                                .tint(selectedAccent.color)
                        }
                        .padding(16)
                        .glassCard(cornerRadius: 16, tint: selectedAccent.color)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(selectedAccent.color.opacity(0.25), lineWidth: 1)
                        )

                        // Accent color picker
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Accent", systemImage: "paintpalette")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(ThemeManager.t3)
                                .kerning(1)

                            HStack(spacing: 10) {
                                ForEach(NoteAccent.allCases, id: \.self) { accent in
                                    AccentSwatch(accent: accent, isSelected: selectedAccent == accent) {
                                        withAnimation(.spring) { selectedAccent = accent }
                                        Haptics.selection()
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .glassCard(cornerRadius: 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.07), lineWidth: 1)
                        )

                        // Tags field
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Tags (comma separated)", systemImage: "tag")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(ThemeManager.t3)
                                .kerning(1)

                            TextField("ideas, work, personal...", text: $tags)
                                .font(.system(size: 15, weight: .regular, design: .monospaced))
                                .foregroundStyle(ThemeManager.t1)
                                .tint(selectedAccent.color)
                                .autocapitalization(.none)
                        }
                        .padding(16)
                        .glassCard(cornerRadius: 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.07), lineWidth: 1)
                        )

                        // Quick start body
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Start writing (optional)", systemImage: "pencil")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(ThemeManager.t3)
                                .kerning(1)

                            TextEditor(text: $noteBody)
                                .focused($bodyFocused)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(ThemeManager.t1)
                                .tint(selectedAccent.color)
                                .frame(minHeight: 120)
                                .scrollContentBackground(.hidden)
                        }
                        .padding(16)
                        .glassCard(cornerRadius: 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.07), lineWidth: 1)
                        )

                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
    }

    private func save() {
        let note = Note(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            body: noteBody,
            tags: parsedTags,
            accentColor: selectedAccent
        )
        onCreate(note)
        Haptics.notification(.success)
        dismiss()
    }
}

// MARK: - Sheet Header

struct SheetHeader: View {
    let title: String
    let accent: Color
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        HStack {
            Button("Cancel", action: onCancel)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(ThemeManager.t2)

            Spacer()

            // Title with accent gradient pip
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 100)
                    .fill(LinearGradient(colors: [accent, ThemeManager.teal],
                                        startPoint: .leading, endPoint: .trailing))
                    .frame(width: 20, height: 10)
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundStyle(ThemeManager.t1)
            }

            Spacer()

            Button("Save", action: onSave)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(ThemeManager.gold)
        }
    }
}

// MARK: - Accent Swatch

struct AccentSwatch: View {
    let accent: NoteAccent
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(accent.color)
                    .frame(width: 32, height: 32)

                if isSelected {
                    Circle()
                        .stroke(Color.white.opacity(0.9), lineWidth: 2.5)
                        .frame(width: 38, height: 38)

                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.black)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring, value: isSelected)
    }
}
