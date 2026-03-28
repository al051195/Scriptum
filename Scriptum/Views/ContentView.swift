import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: NoteStore
    @EnvironmentObject var aiService: AIService
    @State private var selectedNote: Note? = nil
    @State private var showNewNote = false
    @State private var showSettings = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    var body: some View {
        ZStack {
            // Shared mesh background
            MeshBackgroundView()
                .ignoresSafeArea()

            if UIDevice.current.userInterfaceIdiom == .pad {
                // iPad: split view
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    NoteListView(
                        selectedNote: $selectedNote,
                        showSettings: $showSettings
                    )
                    .navigationSplitViewColumnWidth(min: 300, ideal: 360, max: 420)
                } detail: {
                    if let note = selectedNote {
                        NoteEditorView(note: note) { updated in
                            store.update(updated)
                        }
                    } else {
                        EmptyEditorPlaceholder()
                    }
                }
                .navigationSplitViewStyle(.balanced)
            } else {
                // iPhone: stack navigation
                NavigationStack {
                    NoteListView(
                        selectedNote: $selectedNote,
                        showSettings: $showSettings
                    )
                    .navigationDestination(item: $selectedNote) { note in
                        NoteEditorView(note: note) { updated in
                            store.update(updated)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            store.load()
        }
    }
}

// MARK: - Empty State Placeholder (iPad detail)

struct EmptyEditorPlaceholder: View {
    var body: some View {
        ZStack {
            MeshBackgroundView().ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "note.text")
                    .font(.system(size: 52, weight: .ultraLight))
                    .foregroundStyle(ThemeManager.t2)
                Text("Select a note")
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(ThemeManager.t2)
                Text("Choose from the list or create something new")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(ThemeManager.t3)
                    .multilineTextAlignment(.center)
            }
            .padding(40)
        }
    }
}
