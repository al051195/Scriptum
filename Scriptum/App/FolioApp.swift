import SwiftUI

@main
struct FolioApp: App {
    @StateObject private var store = NoteStore()
    @StateObject private var aiService = AIService()
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(aiService)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
}
