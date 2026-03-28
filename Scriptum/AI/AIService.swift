import Foundation
import SwiftUI
import Combine

#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
final class AIService: ObservableObject {

    // MARK: - Published State

    @AppStorage("folio.ai.enabled") var isEnabled: Bool = false
    @AppStorage("folio.ai.modelDownloaded") var modelDownloaded: Bool = false

    @Published var downloadProgress: Double = 0
    @Published var isDownloading: Bool = false
    @Published var isProcessing: Bool = false
    @Published var downloadError: String? = nil

    // MARK: - Availability

    private var sessionAvailable: Bool {
        if #available(iOS 26.0, *) {
            return true
        }
        return false
    }

    // MARK: - Smart Features

    func suggestTitle(for body: String) async -> String? {
        guard isEnabled, !body.isEmpty else { return nil }

        isProcessing = true
        defer { isProcessing = false }

        if sessionAvailable {
            if #available(iOS 26.0, *) {
                return await generateTitleFoundationModels(body: body)
            } else {
                return heuristicTitle(for: body)
            }
        } else {
            return heuristicTitle(for: body)
        }
    }

    func summarize(_ note: Note) async -> String? {
        guard isEnabled, note.body.count > 200 else { return nil }

        isProcessing = true
        defer { isProcessing = false }

        if sessionAvailable {
            if #available(iOS 26.0, *) {
                return await summarizeFoundationModels(note: note)
            } else {
                return heuristicSummary(for: note.body)
            }
        } else {
            return heuristicSummary(for: note.body)
        }
    }

    func suggestTags(for note: Note) async -> [String] {
        guard isEnabled else { return [] }

        isProcessing = true
        defer { isProcessing = false }

        if sessionAvailable {
            if #available(iOS 26.0, *) {
                return await suggestTagsFoundationModels(note: note)
            } else {
                return heuristicTags(for: note.body)
            }
        } else {
            return heuristicTags(for: note.body)
        }
    }

    func continueWriting(_ note: Note) async -> String? {
        guard isEnabled else { return nil }

        isProcessing = true
        defer { isProcessing = false }

        if sessionAvailable {
            if #available(iOS 26.0, *) {
                return await continueWritingFoundationModels(note: note)
            } else {
                return nil
            }
        }

        return nil
    }

    // MARK: - Foundation Models (iOS 26+)

    @available(iOS 26.0, *)
    private func makeSession() -> LanguageModelSession {
        return LanguageModelSession()
    }

    @available(iOS 26.0, *)
    private func generateTitleFoundationModels(body: String) async -> String? {
        do {
            let session = makeSession()
            let prompt = """
            Generate a short, punchy title (3-6 words). Return ONLY the title.

            \(body.prefix(500))
            """

            let response = try await session.respond(to: prompt)
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return heuristicTitle(for: body)
        }
    }

    @available(iOS 26.0, *)
    private func summarizeFoundationModels(note: Note) async -> String? {
        do {
            let session = makeSession()
            let prompt = """
            Summarize as 3-5 bullet points using "•".

            Title: \(note.title)
            \(note.body.prefix(1000))
            """

            let response = try await session.respond(to: prompt)
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return heuristicSummary(for: note.body)
        }
    }

    @available(iOS 26.0, *)
    private func suggestTagsFoundationModels(note: Note) async -> [String] {
        do {
            let session = makeSession()
            let prompt = """
            Suggest 2-4 lowercase tags separated by commas.

            Title: \(note.title)
            \(note.body.prefix(400))
            """

            let response = try await session.respond(to: prompt)

            return response.content
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty }

        } catch {
            return heuristicTags(for: note.body)
        }
    }

    @available(iOS 26.0, *)
    private func continueWritingFoundationModels(note: Note) async -> String? {
        do {
            let session = makeSession()
            let prompt = """
            Continue this note naturally in 2-3 sentences.

            Title: \(note.title)
            \(note.body.suffix(600))
            """

            let response = try await session.respond(to: prompt)
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)

        } catch {
            return nil
        }
    }

    // MARK: - Heuristics

    private func heuristicTitle(for body: String) -> String? {
        guard let firstLine = body
            .split(separator: "\n", omittingEmptySubsequences: true)
            .first else { return nil }

        return firstLine
            .split(separator: " ")
            .prefix(6)
            .joined(separator: " ")
    }

    private func heuristicSummary(for body: String) -> String? {
        let sentences = body
            .components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.count > 20 }
            .prefix(4)

        guard !sentences.isEmpty else { return nil }

        return sentences.map { "• \($0)" }.joined(separator: "\n")
    }

    private func heuristicTags(for body: String) -> [String] {
        let patterns: [(String, String)] = [
            ("recipe|ingredient|cook|bake|food", "food"),
            ("meeting|agenda|action|discuss", "work"),
            ("read|book|chapter|author|novel", "books"),
            ("idea|concept|design|think|vision", "ideas"),
            ("todo|task|done|complete|list", "tasks"),
            ("journal|felt|feeling|day|today", "journal"),
            ("code|function|swift|app|develop", "dev"),
            ("travel|trip|flight|hotel|visit", "travel"),
        ]

        let lower = body.lowercased()

        return patterns.compactMap { pattern, tag in
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                return nil
            }

            let range = NSRange(lower.startIndex..<lower.endIndex, in: lower)
            return regex.firstMatch(in: lower, options: [], range: range) != nil ? tag : nil
        }
    }

    // MARK: - Enable / Disable

    func enableAI() async {
        if sessionAvailable {
            isEnabled = true
            modelDownloaded = true
        } else {
            downloadError = "AI features require iOS 26+ with Foundation Models support."
        }
    }

    func disableAI() {
        isEnabled = false
    }
}

#if !canImport(FoundationModels)
@available(iOS 26.0, *)
private class LanguageModelSession {
    struct Response { let content: String }

    func respond(to prompt: String) async throws -> Response {
        throw NSError(domain: "FoundationModels", code: -1)
    }
}
#endif

