import AppIntents
import SwiftUI
import UIKit
import UserNotifications

struct AnalyzeScreenIntent: AppIntent {
    static var title: LocalizedStringResource = "Analyzovat obrazovku"
    static var description = IntentDescription("Sejme snímek obrazovky z Apple Zkratky a okamžitě vrátí správnou odpověď a barevný symbol (▲ ◆ ● ■).")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Snímek obrazovky", supportedTypeIdentifiers: ["public.image"])
    var screenshot: IntentFile

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let image = UIImage(data: screenshot.data) else {
            await sendBanner(title: "❗ Chyba snímku", body: "Nepodařilo se načíst obrázek.")
            return .result(dialog: "❗ Chyba: neplatný obrázek.")
        }

        let apiKey = await MainActor.run { AppStore.shared.activeApiKey() }
        let stealth = await MainActor.run { AppStore.shared.stealthMode }
        let useHaptics = await MainActor.run { AppStore.shared.hapticFeedback }

        do {
            let result = try await GeminiService.shared.analyze(image: image, apiKey: apiKey)
            await MainActor.run {
                AppStore.shared.addResult(result)
            }

            if useHaptics {
                await triggerHapticPattern(count: result.optionShape.hapticCount)
            }

            let title: String
            let body: String
            if stealth && result.optionShape != .unknown {
                title = "\(result.optionShape.emoji) \(result.optionShape.colorNameCz)"
                body = result.directAnswer
            } else {
                title = "\(result.optionShape.emoji) \(result.directAnswer)"
                body = result.explanation.isEmpty ? "\(result.modelUsed) • \(result.durationMs) ms" : result.explanation
            }

            await sendBanner(title: title, body: body)
            return .result(dialog: IntentDialog(stringLiteral: title))
        } catch {
            await sendBanner(title: "❗ Chyba analýzy", body: error.localizedDescription)
            return .result(dialog: "❗ Chyba: \(error.localizedDescription)")
        }
    }

    private func sendBanner(title: String, body: String) async {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = nil
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try? await center.add(request)
    }

    @MainActor
    private func triggerHapticPattern(count: Int) async {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        for i in 0..<count {
            generator.impactOccurred()
            if i < count - 1 {
                try? await Task.sleep(nanoseconds: 140_000_000)
            }
        }
    }
}

struct CerectShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AnalyzeScreenIntent(),
            phrases: [
                "Analyzuj obrazovku v \(.applicationName)",
                "Vyřeš kvíz v \(.applicationName)"
            ],
            shortTitle: "Analyzovat obrazovku",
            systemImageName: "sparkles"
        )
    }
}
