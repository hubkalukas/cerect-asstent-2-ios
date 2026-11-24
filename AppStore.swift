import Foundation
import SwiftUI

@MainActor
final class AppStore: ObservableObject {
    static let shared = AppStore()

    private let historyKey = "cerect_ios_history_v1"
    private let stealthKey = "cerect_ios_stealth_v1"
    private let hapticKey = "cerect_ios_haptic_v1"
    private let customKeyKey = "cerect_ios_custom_key_v1"

    @Published var history: [AnswerResult] = []
    @Published var stealthMode: Bool {
        didSet { UserDefaults.standard.set(stealthMode, forKey: stealthKey) }
    }
    @Published var hapticFeedback: Bool {
        didSet { UserDefaults.standard.set(hapticFeedback, forKey: hapticKey) }
    }
    @Published var lastResult: AnswerResult?

    private init() {
        self.stealthMode = UserDefaults.standard.object(forKey: stealthKey) as? Bool ?? true
        self.hapticFeedback = UserDefaults.standard.object(forKey: hapticKey) as? Bool ?? true
        loadHistory()
    }

    func activeApiKey() -> String {
        let custom = (UserDefaults.standard.string(forKey: customKeyKey) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return custom.isEmpty ? SecretVault.defaultApiKey() : custom
    }

    func saveCustomApiKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            UserDefaults.standard.removeObject(forKey: customKeyKey)
        } else {
            UserDefaults.standard.set(trimmed, forKey: customKeyKey)
        }
    }

    func addResult(_ item: AnswerResult) {
        lastResult = item
        history.insert(item, at: 0)
        if history.count > 100 {
            history = Array(history.prefix(100))
        }
        persistHistory()
    }

    func clearHistory() {
        history.removeAll()
        lastResult = nil
        UserDefaults.standard.removeObject(forKey: historyKey)
    }

    func reloadHistory() {
        loadHistory()
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode([AnswerResult].self, from: data) else {
            return
        }
        history = decoded
    }

    private func persistHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }
}
