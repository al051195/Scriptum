import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var aiService: AIService
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var store: NoteStore
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirm = false
    @State private var aiToggleAnimating = false

    var body: some View {
        ZStack {
            MeshBackgroundView().ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    settingsHeader

                    // Appearance
                    SettingsSection(title: "Appearance", icon: "paintbrush", color: ThemeManager.teal) {
                        ThemePickerRow(theme: $themeManager.theme)
                    }

                    // AI
                    SettingsSection(title: "Intelligence", icon: "wand.and.stars", color: ThemeManager.gold) {
                        AIToggleRow(
                            isEnabled: Binding(
                                get: { aiService.isEnabled },
                                set: { enabled in
                                    Task {
                                        if enabled { await aiService.enableAI() }
                                        else { aiService.disableAI() }
                                    }
                                    Haptics.impact(.medium)
                                }
                            )
                        )

                        if let error = aiService.downloadError {
                            InfoRow(
                                icon: "exclamationmark.triangle",
                                iconColor: ThemeManager.rose,
                                text: error
                            )
                        }

                        InfoRow(
                            icon: "lock.shield",
                            iconColor: ThemeManager.teal,
                            text: "All AI features run entirely on-device. Nothing leaves your iPhone."
                        )
                        InfoRow(
                            icon: "cpu",
                            iconColor: ThemeManager.sky,
                            text: "Powered by Apple Foundation Models (iOS 26+). Requires A17 Pro or M-series chip."
                        )
                    }

                    // Sorting & Display
                    SettingsSection(title: "Display", icon: "arrow.up.arrow.down", color: ThemeManager.sky) {
                        SortPickerRow(sort: $store.sortOption)
                    }

                    // About
                    SettingsSection(title: "About", icon: "info.circle", color: ThemeManager.lavender) {
                        AboutRow(label: "Version", value: "1.0.0")
                        AboutRow(label: "Notes", value: "\(store.notes.count)")
                        AboutRow(label: "Words Total", value: "\(store.notes.reduce(0) { $0 + $1.wordCount })")
                    }

                    // Danger zone
                    SettingsSection(title: "Data", icon: "externaldrive", color: ThemeManager.rose) {
                        Button {
                            showDeleteConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(ThemeManager.rose)
                                    .frame(width: 24)
                                Text("Delete All Notes")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(ThemeManager.rose)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)
        .confirmationDialog(
            "Delete all \(store.notes.count) notes?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete All", role: .destructive) {
                store.notes.removeAll()
                store.save()
                Haptics.notification(.warning)
                dismiss()
            }
        }
    }

    private var settingsHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 100)
                        .fill(LinearGradient(colors: [ThemeManager.gold, ThemeManager.teal],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: 24, height: 12)
                    Text("Folio")
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundStyle(ThemeManager.t1)
                }
                Text("Settings")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(ThemeManager.t3)
                    .kerning(1)
            }
            Spacer()
            Button { dismiss() } label: {
                if #available(iOS 26.0, *) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(ThemeManager.t3)
                        .frame(width: 34, height: 34)
                        .glassEffect(.clear.interactive())
                } else {
                    // Fallback on earlier versions
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(ThemeManager.t3)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section label
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(colors: [ThemeManager.gold, ThemeManager.teal],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: 16, height: 2)
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(color)
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(ThemeManager.t3)
                    .kerning(1.2)
            }

            VStack(spacing: 0) {
                content()
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
            }
            .glassCard(cornerRadius: 20)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            )
        }
    }
}

// MARK: - AI Toggle Row

struct AIToggleRow: View {
    @Binding var isEnabled: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isEnabled ? ThemeManager.goldDim : Color.white.opacity(0.07))
                    .frame(width: 40, height: 40)
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isEnabled ? ThemeManager.gold : ThemeManager.t3)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("AI Features")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ThemeManager.t1)
                Text(isEnabled ? "Enabled — On-device processing" : "Disabled by default")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isEnabled ? ThemeManager.teal : ThemeManager.t3)
            }

            Spacer()

            Toggle("", isOn: $isEnabled)
                .tint(ThemeManager.gold)
                .labelsHidden()
        }
    }
}

// MARK: - Theme Picker Row

struct ThemePickerRow: View {
    @Binding var theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(ThemeManager.tealDim)
                        .frame(width: 40, height: 40)
                    Image(systemName: "circle.lefthalf.filled")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(ThemeManager.teal)
                }
                Text("Appearance")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ThemeManager.t1)
                Spacer()
            }

            HStack(spacing: 8) {
                ForEach(AppTheme.allCases, id: \.self) { t in
                    Button {
                        withAnimation(.spring) { theme = t }
                        Haptics.selection()
                    } label: {
                        Text(t.label)
                            .font(.system(size: 13, weight: theme == t ? .bold : .medium))
                            .foregroundStyle(theme == t ? .black : ThemeManager.t2)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(theme == t ? ThemeManager.teal : Color.white.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                    .animation(.spring, value: theme)
                }
            }
        }
    }
}

// MARK: - Sort Picker Row

struct SortPickerRow: View {
    @Binding var sort: SortOption

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: "7DD3FC").opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(ThemeManager.sky)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Sort Notes By")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ThemeManager.t1)
                Text(sort.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ThemeManager.t3)
            }

            Spacer()

            Menu {
                ForEach(SortOption.allCases, id: \.self) { opt in
                    Button {
                        withAnimation(.spring) { sort = opt }
                        Haptics.selection()
                    } label: {
                        if sort == opt {
                            Label(opt.rawValue, systemImage: "checkmark")
                        } else {
                            Text(opt.rawValue)
                        }
                    }
                }
            } label: {
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(ThemeManager.t3)
            }
        }
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let icon: String
    let iconColor: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 20)
                .padding(.top, 1)

            Text(text)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(ThemeManager.t2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 2)
    }
}

// MARK: - About Row

struct AboutRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(ThemeManager.t2)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(ThemeManager.t1)
        }
        .padding(.vertical, 4)
    }
}
