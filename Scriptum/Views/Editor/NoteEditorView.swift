import SwiftUI

struct NoteEditorView: View {
    let note: Note
    let onSave: (Note) -> Void

    @EnvironmentObject var aiService: AIService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var draft: Note
    @State private var showAIPanel = false
    @State private var showTagEditor = false
    @State private var showAccentPicker = false
    @State private var saveDebouncer: Task<Void, Never>? = nil
    @State private var aiSuggestion: String? = nil
    @State private var isGeneratingAI = false
    @State private var aiMode: AIMode = .summarize

    @FocusState private var titleFocused: Bool
    @FocusState private var bodyFocused: Bool

    private var accent: Color { draft.accentColor.color }

    enum AIMode: String, CaseIterable {
        case summarize = "Summarize"
        case suggestTitle = "Suggest Title"
        case suggestTags = "Suggest Tags"
        case continueWriting = "Continue Writing"
    }

    init(note: Note, onSave: @escaping (Note) -> Void) {
        self.note = note
        self.onSave = onSave
        _draft = State(initialValue: note)
    }

    var body: some View {
        ZStack {
            MeshBackgroundView().ignoresSafeArea()

            VStack(spacing: 0) {
                // Editor nav bar
                EditorNavBar(
                    draft: $draft,
                    accent: accent,
                    showAIPanel: $showAIPanel,
                    showAccentPicker: $showAccentPicker,
                    aiEnabled: aiService.isEnabled
                ) {
                    dismiss()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)

                // Main editor area
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Title
                        TextField("Title", text: $draft.title, axis: .vertical)
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundStyle(ThemeManager.t1)
                            .tint(accent)
                            .focused($titleFocused)
                            .submitLabel(.next)
                            .onSubmit { bodyFocused = true }
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                            .padding(.bottom, 16)

                        // Metadata strip
                        MetadataStrip(note: draft, accent: accent)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)

                        Divider()
                            .overlay(Color.white.opacity(0.06))
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)

                        // Tags
                        if !draft.tags.isEmpty || showTagEditor {
                            TagEditorRow(tags: $draft.tags, accent: accent, showEditor: $showTagEditor)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 16)
                        }

                        // Body
                        TextEditor(text: $draft.body)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(ThemeManager.t1)
                            .tint(accent)
                            .focused($bodyFocused)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 300)
                            .padding(.horizontal, 16)

                        // AI suggestion panel
                        if let suggestion = aiSuggestion {
                            AISuggestionCard(
                                suggestion: suggestion,
                                mode: aiMode,
                                accent: accent
                            ) { accepted in
                                if accepted { applyAISuggestion(suggestion) }
                                aiSuggestion = nil
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        Spacer().frame(height: 120)
                    }
                }

                // Floating formatting toolbar
                FormattingToolbar(
                    accent: accent,
                    showTagEditor: $showTagEditor,
                    showAIPanel: $showAIPanel,
                    aiEnabled: aiService.isEnabled
                ) { action in
                    handleFormatting(action)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
        }
        .navigationBarHidden(true)
        .onChange(of: draft.title) { _, _ in scheduleSave() }
        .onChange(of: draft.body)  { _, _ in scheduleSave() }
        .onChange(of: draft.tags)  { _, _ in scheduleSave() }
        .onChange(of: draft.accentColor) { _, _ in scheduleSave() }
        .sheet(isPresented: $showAIPanel) {
            AIPanelSheet(
                note: draft,
                isGenerating: $isGeneratingAI,
                suggestion: $aiSuggestion,
                mode: $aiMode
            ) { mode in
                showAIPanel = false
                Task { await runAI(mode: mode) }
            }
        }
        .confirmationDialog("Note Colour", isPresented: $showAccentPicker) {
            ForEach(NoteAccent.allCases, id: \.self) { a in
                Button(a.label) {
                    withAnimation(.spring) { draft.accentColor = a }
                }
            }
        }
    }

    // MARK: - Auto-save

    private func scheduleSave() {
        saveDebouncer?.cancel()
        saveDebouncer = Task {
            try? await Task.sleep(nanoseconds: 600_000_000) // 0.6s debounce
            guard !Task.isCancelled else { return }
            await MainActor.run { onSave(draft) }
        }
    }

    // MARK: - Formatting Actions

    enum FormatAction { case bold, italic, bullet, heading, divider }

    private func handleFormatting(_ action: FormatAction) {
        Haptics.impact()
        switch action {
        case .bold:    draft.body += "**text**"
        case .italic:  draft.body += "_text_"
        case .bullet:  draft.body += "\n• "
        case .heading: draft.body += "\n## "
        case .divider: draft.body += "\n---\n"
        }
        bodyFocused = true
    }

    // MARK: - AI

    private func runAI(mode: AIMode) async {
        withAnimation(.spring) { isGeneratingAI = true }
        defer { withAnimation(.spring) { isGeneratingAI = false } }
        aiMode = mode

        switch mode {
        case .summarize:
            aiSuggestion = await aiService.summarize(draft)
        case .suggestTitle:
            if let t = await aiService.suggestTitle(for: draft.body) {
                withAnimation(.spring) { aiSuggestion = t }
            }
        case .suggestTags:
            let tags = await aiService.suggestTags(for: draft)
            if !tags.isEmpty { aiSuggestion = tags.joined(separator: ", ") }
        case .continueWriting:
            aiSuggestion = await aiService.continueWriting(draft)
        }
    }

    private func applyAISuggestion(_ suggestion: String) {
        withAnimation(.spring) {
            switch aiMode {
            case .suggestTitle:
                draft.title = suggestion
                titleFocused = true
            case .suggestTags:
                let newTags = suggestion.split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                    .filter { !$0.isEmpty }
                draft.tags = Array(Set(draft.tags + newTags))
            case .summarize, .continueWriting:
                draft.body += "\n\n\(suggestion)"
                bodyFocused = true
            }
        }
        Haptics.notification(.success)
    }
}

// MARK: - Editor Nav Bar

struct EditorNavBar: View {
    @Binding var draft: Note
    let accent: Color
    @Binding var showAIPanel: Bool
    @Binding var showAccentPicker: Bool
    let aiEnabled: Bool
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Back
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(ThemeManager.t2)
                    .frame(width: 38, height: 38)
                    .glassCard(cornerRadius: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.07), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            // Colour dot
            Button { showAccentPicker = true } label: {
                Circle()
                    .fill(accent)
                    .frame(width: 18, height: 18)
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1.5))
                    .frame(width: 38, height: 38)
                    .glassCard(cornerRadius: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.07), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            // AI button (only if enabled)
            if aiEnabled {
                Button { showAIPanel = true } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 13, weight: .semibold))
                        Text("AI")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .glassCard(cornerRadius: 12, tint: accent)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(accent.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Metadata Strip

struct MetadataStrip: View {
    let note: Note
    let accent: Color

    var body: some View {
        HStack(spacing: 16) {
            Label(note.createdAt.relativeFormatted, systemImage: "clock")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(ThemeManager.t3)

            if note.wordCount > 0 {
                Text("·").foregroundStyle(ThemeManager.t3)
                Label("\(note.wordCount) words", systemImage: "text.alignleft")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(ThemeManager.t3)
            }

            Spacer()

            // Accent pip
            RoundedRectangle(cornerRadius: 100)
                .fill(LinearGradient(colors: [accent, ThemeManager.teal],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: 20, height: 8)
                .shimmer()
        }
    }
}

// MARK: - Tag Editor Row

struct TagEditorRow: View {
    @Binding var tags: [String]
    let accent: Color
    @Binding var showEditor: Bool
    @State private var editingText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "tag")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(ThemeManager.t3)

                FlowLayout(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text(tag)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(accent)

                            Button {
                                tags.removeAll { $0 == tag }
                                Haptics.impact()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(accent.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(accent.opacity(0.15)))
                        .overlay(Capsule().stroke(accent.opacity(0.25), lineWidth: 1))
                    }

                    // Add tag field
                    TextField("add tag", text: $editingText)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(ThemeManager.t2)
                        .tint(accent)
                        .frame(width: 80)
                        .onSubmit { addTag() }
                        .autocapitalization(.none)
                }
            }
        }
    }

    private func addTag() {
        let tag = editingText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !tag.isEmpty && !tags.contains(tag) {
            tags.append(tag)
            Haptics.selection()
        }
        editingText = ""
    }
}

// MARK: - Formatting Toolbar

struct FormattingToolbar: View {
    let accent: Color
    @Binding var showTagEditor: Bool
    @Binding var showAIPanel: Bool
    let aiEnabled: Bool
    let onAction: (NoteEditorView.FormatAction) -> Void

    var body: some View {
        HStack(spacing: 4) {
            FormatButton(icon: "bold", label: "B") { onAction(.bold) }
            FormatButton(icon: "italic", label: "I") { onAction(.italic) }
            FormatButton(icon: "list.bullet", label: "•") { onAction(.bullet) }
            FormatButton(icon: "textformat.size.larger", label: "H") { onAction(.heading) }
            FormatButton(icon: "minus", label: "—") { onAction(.divider) }

            Spacer()

            // Tag toggle
            Button {
                withAnimation(.spring) { showTagEditor.toggle() }
                Haptics.impact()
            } label: {
                Image(systemName: "tag")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(showTagEditor ? accent : ThemeManager.t3)
            }
            .frame(width: 38, height: 38)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassToolbar()
        .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}

struct FormatButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(ThemeManager.t2)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Color.white.opacity(0.0)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AI Panel Sheet

struct AIPanelSheet: View {
    let note: Note
    @Binding var isGenerating: Bool
    @Binding var suggestion: String?
    @Binding var mode: NoteEditorView.AIMode
    let onAction: (NoteEditorView.AIMode) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            MeshBackgroundView().ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "wand.and.stars")
                                .foregroundStyle(ThemeManager.gold)
                            Text("AI Assistant")
                                .font(.system(size: 18, weight: .bold, design: .serif))
                                .foregroundStyle(ThemeManager.t1)
                        }
                        Text("On-device · Private")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(ThemeManager.teal)
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(ThemeManager.t3)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                }

                // Mode buttons — grid
                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                    ForEach(NoteEditorView.AIMode.allCases, id: \.self) { m in
                        AIActionButton(mode: m, isSelected: mode == m) {
                            mode = m
                            onAction(m)
                        }
                    }
                }

                Spacer()
            }
            .padding(24)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
    }
}

struct AIActionButton: View {
    let mode: NoteEditorView.AIMode
    let isSelected: Bool
    let action: () -> Void

    private var icon: String {
        switch mode {
        case .summarize:       return "list.bullet.clipboard"
        case .suggestTitle:    return "textformat.characters"
        case .suggestTags:     return "tag.fill"
        case .continueWriting: return "arrow.forward.to.line"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isSelected ? .black : ThemeManager.gold)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.rawValue)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(isSelected ? .black : ThemeManager.t1)
                }
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? ThemeManager.gold : Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? ThemeManager.gold.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring, value: isSelected)
    }
}

// MARK: - AI Suggestion Card

struct AISuggestionCard: View {
    let suggestion: String
    let mode: NoteEditorView.AIMode
    let accent: Color
    let onDecision: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ThemeManager.gold)
                Text(mode.rawValue)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(ThemeManager.gold)
                    .kerning(0.8)
                Spacer()
                Text("AI Suggestion")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(ThemeManager.t3)
            }

            Text(suggestion)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(ThemeManager.t1)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button("Apply") { onDecision(true) }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(ThemeManager.gold))

                Button("Dismiss") { onDecision(false) }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(ThemeManager.t2)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.white.opacity(0.07)))
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 16, tint: ThemeManager.gold)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(ThemeManager.gold.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Flow Layout (for tags)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        return CGSize(
            width: proposal.width ?? 0,
            height: rows.last.map { $0.maxY } ?? 0
        )
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: ProposedViewSize(width: bounds.width, height: nil), subviews: subviews)
        for row in rows {
            for item in row.items {
                item.view.place(at: CGPoint(x: bounds.minX + item.x, y: bounds.minY + item.y), proposal: .unspecified)
            }
        }
    }

    private struct Row {
        struct Item { let view: LayoutSubview; let x, y: CGFloat }
        var items: [Item] = []
        var maxY: CGFloat = 0
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()
        var x: CGFloat = 0
        var y: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && !currentRow.items.isEmpty {
                currentRow.maxY = y + (currentRow.items.map { $0.view.sizeThatFits(.unspecified).height }.max() ?? 0)
                rows.append(currentRow)
                currentRow = Row()
                y = currentRow.maxY + spacing
                x = 0
            }
            currentRow.items.append(.init(view: view, x: x, y: y))
            x += size.width + spacing
        }
        if !currentRow.items.isEmpty {
            currentRow.maxY = y + (currentRow.items.map { $0.view.sizeThatFits(.unspecified).height }.max() ?? 0)
            rows.append(currentRow)
        }
        return rows
    }
}
