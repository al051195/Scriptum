import SwiftUI

struct NoteListView: View {
    @EnvironmentObject var store: NoteStore
    @EnvironmentObject var aiService: AIService
    @Binding var selectedNote: Note?
    @Binding var showSettings: Bool

    @State private var showNewNoteSheet = false
    @State private var showSortMenu = false
    @State private var searchFocused = false
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // List
            ScrollView {
                VStack(spacing: 0) {
                    // Spacer for floating navbar
                    Spacer().frame(height: 8)

                    // Search bar
                    SearchBarView(
                        text: $store.searchQuery,
                        isFocused: $searchFocused
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .revealIn(delay: 0.1)

                    // Tag filter strip
                    if !store.allTags.isEmpty {
                        TagFilterStrip(
                            tags: store.allTags,
                            selected: $store.selectedTag
                        )
                        .padding(.bottom, 16)
                        .revealIn(delay: 0.15)
                    }

                    // Pinned section
                    if !store.pinnedNotes.isEmpty {
                        SectionHeader(title: "Pinned", icon: "pin.fill", color: ThemeManager.gold)
                            .padding(.horizontal, 16)
                            .revealIn(delay: 0.2)

                        LazyVStack(spacing: 12) {
                            ForEach(store.pinnedNotes) { note in
                                NoteCard(note: note, isSelected: selectedNote?.id == note.id) {
                                    withAnimation(.spring) { selectedNote = note }
                                    Haptics.selection()
                                }
                                .contextMenu { noteContextMenu(note) }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    deleteSwipeAction(note)
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    pinSwipeAction(note)
                                }
                                .revealIn(delay: 0.05)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }

                    // All notes section
                    if !store.unpinnedNotes.isEmpty {
                        SectionHeader(
                            title: store.searchQuery.isEmpty && store.selectedTag == nil ? "Notes" : "Results",
                            icon: "note.text",
                            color: ThemeManager.teal,
                            trailing: {
                                SortButton(showMenu: $showSortMenu)
                            }
                        )
                        .padding(.horizontal, 16)
                        .revealIn(delay: 0.2)

                        LazyVStack(spacing: 12) {
                            ForEach(store.unpinnedNotes) { note in
                                NoteCard(note: note, isSelected: selectedNote?.id == note.id) {
                                    withAnimation(.spring) { selectedNote = note }
                                    Haptics.selection()
                                }
                                .contextMenu { noteContextMenu(note) }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    deleteSwipeAction(note)
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    pinSwipeAction(note)
                                }
                                .revealIn(delay: 0.05)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Empty state
                    if store.pinnedNotes.isEmpty && store.unpinnedNotes.isEmpty {
                        EmptyStateView(hasSearch: !store.searchQuery.isEmpty)
                            .padding(.top, 60)
                    }

                    // Bottom padding for FAB
                    Spacer().frame(height: 120)
                }
                .padding(.top, 8)
            }
            .scrollDismissesKeyboard(.interactively)

            // Floating Action Button
            FloatingActionBar(showSettings: $showSettings) {
                showNewNoteSheet = true
            }
            .padding(.bottom, 16)
        }
        .navigationBarHidden(true)
        .background(Color.clear)
        .confirmationDialog("Sort Notes", isPresented: $showSortMenu) {
            ForEach(SortOption.allCases, id: \.self) { opt in
                Button(opt.rawValue) {
                    withAnimation(.spring) { store.sortOption = opt }
                    Haptics.selection()
                }
            }
        }
        .sheet(isPresented: $showNewNoteSheet) {
            NewNoteSheet { newNote in
                store.add(newNote)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    selectedNote = newNote
                }
            }
        }
        .overlay(alignment: .top) {
            FloatingNavBar(title: "Folio", showSettings: $showSettings)
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func noteContextMenu(_ note: Note) -> some View {
        Button {
            store.togglePin(note)
            Haptics.impact(.medium)
        } label: {
            Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
        }

        Button {
            store.duplicate(note)
            Haptics.impact()
        } label: {
            Label("Duplicate", systemImage: "doc.on.doc")
        }

        Divider()

        Button(role: .destructive) {
            store.delete(note)
            if selectedNote?.id == note.id { selectedNote = nil }
            Haptics.notification(.warning)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: - Swipe Actions

    private func deleteSwipeAction(_ note: Note) -> some View {
        Button(role: .destructive) {
            withAnimation(.spring) {
                store.delete(note)
                if selectedNote?.id == note.id { selectedNote = nil }
            }
            Haptics.notification(.warning)
        } label: {
            Label("Delete", systemImage: "trash")
        }
        .tint(ThemeManager.rose)
    }

    private func pinSwipeAction(_ note: Note) -> some View {
        Button {
            store.togglePin(note)
            Haptics.impact(.medium)
        } label: {
            Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
        }
        .tint(ThemeManager.gold)
    }
}

// MARK: - Floating Nav Bar (glass pill matching HTML nav)

struct FloatingNavBar: View {
    let title: String
    @Binding var showSettings: Bool
    @State private var shimmerPhase: CGFloat = -1

    var body: some View {
        HStack {
            // Brand / Logo area
            HStack(spacing: 10) {
                // Gold-teal pip (matches HTML .nav-pip)
                RoundedRectangle(cornerRadius: 100)
                    .fill(
                        LinearGradient(colors: [ThemeManager.gold, ThemeManager.teal],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: 28, height: 14)
                    .overlay(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.4), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .offset(x: shimmerPhase * 28)
                        .clipped()
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 100))
                    .onAppear {
                        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                            shimmerPhase = 2
                        }
                    }

                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(ThemeManager.t1)
                    .kerning(1.0)
            }

            Spacer()

            // Settings button
            Button {
                showSettings = true
                Haptics.impact()
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(ThemeManager.t2)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.07)))
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 52)
        .liquidGlass(cornerRadius: 40, tint: Color(hex: "09100F"), opacity: 0.35)
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
}

// MARK: - Section Header

struct SectionHeader<Trailing: View>: View {
    let title: String
    let icon: String
    let color: Color
    var trailing: (() -> Trailing)? = nil

    init(title: String, icon: String, color: Color, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.title = title; self.icon = icon; self.color = color; self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 8) {
            // Section bar (matches HTML .sec-tag-bar)
            RoundedRectangle(cornerRadius: 2)
                .fill(LinearGradient(colors: [ThemeManager.gold, ThemeManager.teal],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: 20, height: 2)

            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)

            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(ThemeManager.t3)
                .kerning(1.4)

            Spacer()

            trailing?()
        }
        .padding(.vertical, 8)
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(title: String, icon: String, color: Color) {
        self.init(title: title, icon: icon, color: color, trailing: { EmptyView() })
    }
}

// MARK: - Sort Button

struct SortButton: View {
    @Binding var showMenu: Bool
    var body: some View {
        Button { showMenu = true } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 11, weight: .medium))
                Text("Sort")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
            }
            .foregroundStyle(ThemeManager.t3)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(Color.white.opacity(0.06))
            )
        }
    }
}

// MARK: - Search Bar

struct SearchBarView: View {
    @Binding var text: String
    @Binding var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(ThemeManager.t3)

            TextField("Search notes...", text: $text)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(ThemeManager.t1)
                .tint(ThemeManager.teal)

            if !text.isEmpty {
                Button {
                    text = ""
                    Haptics.selection()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(ThemeManager.t3)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: 16, tint: .clear)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }
}

// MARK: - Tag Filter Strip

struct TagFilterStrip: View {
    let tags: [String]
    @Binding var selected: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All
                TagChip(label: "All", isSelected: selected == nil) {
                    withAnimation(.spring) { selected = nil }
                    Haptics.selection()
                }

                ForEach(tags, id: \.self) { tag in
                    TagChip(label: tag, isSelected: selected == tag) {
                        withAnimation(.spring) { selected = selected == tag ? nil : tag }
                        Haptics.selection()
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct TagChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(isSelected ? Color.black : ThemeManager.t2)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? ThemeManager.gold : Color.white.opacity(0.07))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? ThemeManager.gold.opacity(0.5) : Color.white.opacity(0.10), lineWidth: 1)
                )
        }
        .animation(.spring, value: isSelected)
    }
}

// MARK: - Floating Action Bar

struct FloatingActionBar: View {
    @Binding var showSettings: Bool
    let onNew: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // New note button (primary — gold)
            Button(action: {
                onNew()
                Haptics.impact(.medium)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                    Text("New Note")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(LinearGradient(
                            colors: [ThemeManager.gold, Color(hex: "F0A500")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .shadow(color: ThemeManager.gold.opacity(0.35), radius: 16, y: 6)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .glassToolbar()
        .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 24, y: 8)
        .padding(.horizontal, 40)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let hasSearch: Bool

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(ThemeManager.goldDim)
                    .frame(width: 80, height: 80)
                Image(systemName: hasSearch ? "magnifyingglass" : "note.text.badge.plus")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(ThemeManager.gold)
            }

            VStack(spacing: 8) {
                Text(hasSearch ? "No results found" : "Your notebook awaits")
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundStyle(ThemeManager.t1)

                Text(hasSearch ? "Try different keywords or clear the search" : "Tap the button below to write your first note")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(ThemeManager.t3)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
}
