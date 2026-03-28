# Scriptum — Note-Taking App

A minimal, beautiful iOS note-taking app built with SwiftUI, native Liquid Glass, and optional on-device AI.

---

## Project Structure

```
Scriptum/
├── Scriptum.xcodeproj/
│   └── project.pbxproj
└── Scriptum/
    ├── App/
    │   ├── FolioApp.swift          — @main entry, injects environment objects
    │   └── ContentView.swift       — Root navigation (Stack on iPhone, Split on iPad)
    ├── Models/
    │   └── Note.swift              — Note struct, NoteAccent enum, SortOption, sample data
    ├── ViewModels/
    │   └── NoteStore.swift         — @MainActor store: CRUD, filtering, search, persistence
    ├── Services/
    │   └── ThemeManager.swift      — AppTheme enum, design tokens matching HTML
    ├── AI/
    │   └── AIService.swift         — On-device AI via Foundation Models (iOS 26+), disabled by default
    └── Views/
        ├── ContentView.swift
        ├── Components/
        │   ├── DesignSystem.swift  — liquidGlass(), shimmer(), revealIn(), Haptics, Color(hex:)
        │   └── MeshBackground.swift— Animated MeshGradient (iOS 18+) / Canvas fallback
        ├── Notes/
        │   ├── NoteListView.swift  — Main list, floating glass nav bar, FAB, search, tag filter
        │   ├── NoteCard.swift      — Glass bento card with accent bar, tags, word count
        │   └── NewNoteSheet.swift  — Creation sheet with accent picker
        ├── Editor/
        │   └── NoteEditorView.swift— Full editor: auto-save, AI panel, formatting toolbar, tag editor
        └── Settings/
            └── SettingsView.swift  — Theme, AI toggle, sort, about, danger zone
```

---

## Setup

### Requirements
- **Xcode 26** (Liquid Glass `.glassEffect()` API requires Xcode 26 SDK)
- **iOS 17+** minimum deployment (Liquid Glass degrades gracefully to `.ultraThinMaterial`)
- **iOS 18+** for native `MeshGradient`
- **iOS 26+** for full Liquid Glass and AI features

### Steps
1. Open `Scriptum.xcodeproj` in Xcode 26
2. Set your Team in **Signing & Capabilities**
3. Change `PRODUCT_BUNDLE_IDENTIFIER` from `com.Al051195.Scriptum` to your own reverse-domain ID
4. Build & run on device or simulator

> **Note:** The `.glassEffect()` modifier is only available in the Xcode 26 SDK. On older SDKs the `#if available` guards fall back to `.ultraThinMaterial` + border overlays, which look nearly identical.

---

## Liquid Glass Integration

The app uses Apple's Liquid Glass API throughout via three wrapper modifiers in `DesignSystem.swift`:

| Modifier | Usage | Shape |
|---|---|---|
| `.liquidGlass(cornerRadius:tint:)` | Floating nav bar, sheets | RoundedRectangle |
| `.glassCard(cornerRadius:tint:)` | Note cards, editor panels | RoundedRectangle |
| `.glassToolbar()` | FAB, formatting bar | Capsule |

All three gracefully fall back to `.ultraThinMaterial` + border strokes on iOS < 26.

To enable tinting (e.g. gold on selected card):
```swift
.glassCard(cornerRadius: 20, tint: note.accentColor.color)
```

---


## AI Features

### Architecture
- **Disabled by default** — user must explicitly enable in Settings
- **Fully on-device** — uses Apple's Foundation Models framework (iOS 26+, requires A17 Pro / M-series)
- **No network calls** — zero data leaves the device
- **Graceful heuristics** — on older hardware, heuristic fallbacks provide basic functionality

### Features (when enabled)
| Feature | Trigger |
|---|---|
| Suggest Title | AI panel → "Suggest Title" |
| Summarize | AI panel → "Summarize" |
| Suggest Tags | AI panel → "Suggest Tags" |
| Continue Writing | AI panel → "Continue Writing" |

### Enabling AI (user flow)
1. Open Settings (slider icon in nav bar)
2. Toggle **AI Features** on
3. On iOS 26 + supported hardware: immediately available
4. On unsupported hardware: error message shown, AI remains off

### Implementation Notes

`AIService.swift` uses `LanguageModelSession` from the `FoundationModels` framework:
```swift
import FoundationModels

let session = LanguageModelSession()
let response = try await session.respond(to: prompt)
```

A compile stub is included at the bottom of `AIService.swift` so the code compiles against the iOS 17 SDK too. Remove the `#if !canImport(FoundationModels)` block once your minimum target is iOS 26.

---

## Persistence

Notes are stored in `UserDefaults` as JSON under the key `folio.notes.v1`. Auto-save fires 600ms after any edit (debounced). For production, swap to Core Data or SwiftData for better performance with large note libraries.

---

## License

MIT — use freely, attribute if you like.
