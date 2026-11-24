import PhotosUI
import SwiftUI
import UIKit

struct OverlayView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedItem: PhotosPickerItem?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    heroCard
                    quickScanSection
                    if let result = store.lastResult {
                        lastResultCard(result)
                    }
                    if let err = errorMessage {
                        errorCard(err)
                    }
                    preferencesCard
                    setupGuideCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("cerect asstent 2")
        }
        .onChange(of: selectedItem) { newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    await runScan(image: img)
                }
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
                Text("iOS Asistent je PŘIPRAVEN")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("Bez limitů")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.18))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            Text("Použij poklepání na záda iPhonu (Back Tap), plovoucí bod AssistiveTouch nebo tlačítko níže. Odpověď s barevným symbolem (▲ ◆ ● ■) přijde do ~1 s.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.88))
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color(red: 0.11, green: 0.10, blue: 0.30), Color(red: 0.22, green: 0.19, blue: 0.56)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var quickScanSection: some View {
        HStack(spacing: 12) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                HStack {
                    if isAnalyzing {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "photo.on.rectangle.angled")
                    }
                    Text(isAnalyzing ? "Analyzuji..." : "Vybrat screenshot")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(red: 0.31, green: 0.27, blue: 0.90))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(isAnalyzing)

            Button {
                if let img = UIPasteboard.general.image {
                    Task { await runScan(image: img) }
                } else {
                    errorMessage = "Ve schránce není žádný obrázek."
                }
            } label: {
                HStack {
                    Image(systemName: "doc.on.clipboard")
                    Text("Ze schránky")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.secondarySystemGroupedBackground))
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(isAnalyzing)
        }
    }

    private func lastResultCard(_ res: AnswerResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(res.optionShape.symbol) \(res.optionShape.colorNameCz)")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(res.optionShape.color)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                Spacer()
                Text("\(res.modelUsed) • \(res.durationMs) ms")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(res.directAnswer)
                .font(.title3.bold())
            if !res.explanation.isEmpty {
                Text(res.explanation)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func errorCard(_ message: String) -> some View {
        HStack(spacing: 10) {
            Text("!")
                .font(.headline.bold())
                .frame(width: 28, height: 28)
                .background(Color.red)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Text(message)
                .font(.subheadline)
                .foregroundColor(.red)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var preferencesCard: some View {
        VStack(spacing: 0) {
            Toggle(isOn: $store.stealthMode) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Diskrétní režim (Stealth banner)")
                        .font(.subheadline.weight(.semibold))
                    Text("V horním banneru zobrazí stručný symbol ▲ ◆ ● ■")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()

            Divider().padding(.leading)

            Toggle(isOn: $store.hapticFeedback) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Vibrační kód podle barvy")
                        .font(.subheadline.weight(.semibold))
                    Text("1× ▲ Červená • 2× ◆ Modrá • 3× ● Žlutá • 4× ■ Zelená")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var setupGuideCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nastavení 1-klik skenování na iPhonu")
                .font(.headline)
            Text("1. Otevři aplikaci Zkratky (Shortcuts) → vytvoř novou zkratku:")
                .font(.subheadline)
            Text("   • Krok 1: Pořídit snímek obrazovky\n   • Krok 2: Analyzovat obrazovku (cerect asstent 2)")
                .font(.caption.monospaced())
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Text("2. Otevři Nastavení → Zpřístupnění → Dotyk → Klepnutí na zadní stranu (nebo AssistiveTouch pro plovoucí tečku v rohu) a vyber tuto zkratku.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func runScan(image: UIImage) async {
        isAnalyzing = true
        errorMessage = nil
        defer { isAnalyzing = false }
        do {
            let res = try await GeminiService.shared.analyze(image: image, apiKey: store.activeApiKey())
            store.addResult(res)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
