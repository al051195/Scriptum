import SwiftUI

// MARK: - Note Card
// Matches the bento-card / glass card pattern from the HTML design

struct NoteCard: View {
    let note: Note
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isPressed = false
    @State private var appeared = false

    private var accent: Color { note.accentColor.color }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                // Accent bar (matches HTML diagonal band / border accent)
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(colors: [accent, accent.opacity(0.4)],
                                        startPoint: .top, endPoint: .bottom))
                    .frame(width: 3)
                    .frame(maxHeight: .infinity)
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    // Header row
                    HStack(alignment: .firstTextBaseline) {
                        if note.title.isEmpty {
                            Text("Untitled")
                                .font(.system(size: 17, weight: .semibold, design: .serif))
                                .foregroundStyle(ThemeManager.t3)
                                .italic()
                        } else {
                            Text(note.title)
                                .font(.system(size: 17, weight: .semibold, design: .serif))
                                .foregroundStyle(ThemeManager.t1)
                                .lineLimit(1)
                        }

                        Spacer()

                        // Pin indicator
                        if note.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(ThemeManager.gold)
                                .rotationEffect(.degrees(45))
                        }
                    }

                    // Preview text
                    if !note.preview.isEmpty {
                        Text(note.preview)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(ThemeManager.t2)
                            .lineLimit(2)
                    }

                    // Footer
                    HStack(spacing: 8) {
                        // Date
                        Text(note.modifiedAt.relativeFormatted)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(ThemeManager.t3)

                        // Word count
                        if note.wordCount > 0 {
                            Text("·")
                                .foregroundStyle(ThemeManager.t3)
                            Text("\(note.wordCount) words")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(ThemeManager.t3)
                        }

                        Spacer()

                        // Tags
                        if !note.tags.isEmpty {
                            HStack(spacing: 4) {
                                ForEach(note.tags.prefix(2), id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(accent)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
                                        .background(
                                            Capsule().fill(accent.opacity(0.15))
                                        )
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
            .glassCard(cornerRadius: 20, tint: isSelected ? accent : .clear)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isSelected ? accent.opacity(0.4) : Color.white.opacity(0.07),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .shadow(
                color: isSelected ? accent.opacity(0.15) : .black.opacity(0.3),
                radius: isSelected ? 20 : 12,
                y: 4
            )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        withAnimation(.easeOut(duration: 0.12)) { isPressed = true }
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring) { isPressed = false }
                }
        )
    }
}

// MARK: - Date Formatting

extension Date {
    var relativeFormatted: String {
        let cal = Calendar.current
        if cal.isDateInToday(self) {
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            return f.string(from: self)
        } else if cal.isDateInYesterday(self) {
            return "Yesterday"
        } else if let days = cal.dateComponents([.day], from: self, to: Date()).day, days < 7 {
            let f = DateFormatter()
            f.dateFormat = "EEEE"
            return f.string(from: self)
        } else {
            let f = DateFormatter()
            f.dateFormat = "d MMM"
            return f.string(from: self)
        }
    }
}

// MARK: - Note Card Skeleton (loading placeholder)

struct NoteCardSkeleton: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.08)).frame(width: 160, height: 16)
            RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.05)).frame(maxWidth: .infinity).frame(height: 12)
            RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.05)).frame(width: 200, height: 12)
        }
        .padding(16)
        .glassCard(cornerRadius: 20)
        .shimmer()
    }
}
