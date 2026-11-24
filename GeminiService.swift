import Foundation
import UIKit

enum GeminiError: LocalizedError {
    case missingInput
    case invalidResponse
    case allModelsFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingInput:
            return "Chybí snímek obrazovky i text otázky."
        case .invalidResponse:
            return "Neplatná odpověď ze serveru Gemini."
        case .allModelsFailed(let detail):
            return "Všechny AI modely selhaly: \(detail)"
        }
    }
}

final class GeminiService {
    static let shared = GeminiService()

    // Unlimited paid Tier 1 failover pool (fastest & lowest cost first)
    static let candidateModels: [(id: String, name: String)] = [
        ("gemini-3.5-flash-lite", "Gemini 3.5 Flash Lite"),
        ("gemini-3.1-flash-lite", "Gemini 3.1 Flash Lite"),
        ("gemini-3.6-flash", "Gemini 3.6 Flash"),
        ("gemini-3.8-flash", "Gemini 3.8 Flash")
    ]

    private let systemPrompt = """
    Jsi nejpřesnější kvízový a Kahoot asistent. Pečlivě přečti otázku (pozor na zápory jako NENÍ/NEPATŘÍ/NOT) i všechny nabízené možnosti, u matematiky nebo logiky si krok po kroku ověř výpočet a vyber jedinou 100% správnou odpověď. Pokud je to kvíz s barevnými tlačítky nebo tvary (Kahoot: červený trojúhelník ▲, modrý kosočtverec ◆, žluté kolečko ●, zelený čtverec ■), VŽDY zadej správné 'optionShape' (TRIANGLE, DIAMOND, CIRCLE, SQUARE). Pokud tvary na obrazovce nejsou, dej 'optionShape': 'UNKNOWN'. Vrať VÝHRADNĚ platný JSON objekt bez markdownu: {"correctAnswer": "stručný text správné odpovědi", "optionShape": "TRIANGLE|DIAMOND|CIRCLE|SQUARE|UNKNOWN", "explanation": "krátké vysvětlení česky (max 2 věty)", "confidence": 0.99}
    """

    private lazy var session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 7.0
        cfg.timeoutIntervalForResource = 9.0
        return URLSession(configuration: cfg)
    }()

    func analyze(image: UIImage?, textQuestion: String? = nil, apiKey: String) async throws -> AnswerResult {
        let trimmedText = textQuestion?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard image != nil || !trimmedText.isEmpty else {
            throw GeminiError.missingInput
        }

        var parts: [[String: Any]] = []
        let prompt = trimmedText.isEmpty
            ? systemPrompt
            : "\(systemPrompt)\n\nOtázka:\n\(trimmedText)"
        parts.append(["text": prompt])

        if let img = image, let jpegData = compressImage(img) {
            parts.append([
                "inlineData": [
                    "mimeType": "image/jpeg",
                    "data": jpegData.base64EncodedString()
                ]
            ])
        }

        let payload: [String: Any] = [
            "contents": [["parts": parts]],
            "generationConfig": [
                "temperature": 0.0,
                "maxOutputTokens": 1024,
                "responseMimeType": "application/json"
            ]
        ]

        let bodyData = try JSONSerialization.data(withJSONObject: payload)
        var lastError = "Neznámá chyba"

        for model in Self.candidateModels {
            let start = Date()
            do {
                let rawText = try await callModel(modelId: model.id, apiKey: apiKey, bodyData: bodyData)
                let elapsedMs = Int(Date().timeIntervalSince(start) * 1000)
                return parseAnswer(rawText: rawText, modelName: model.name, durationMs: elapsedMs)
            } catch {
                lastError = "\(model.id): \(error.localizedDescription)"
            }
        }

        throw GeminiError.allModelsFailed(lastError)
    }

    private func callModel(modelId: String, apiKey: String, bodyData: Data) async throws -> String {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(modelId):generateContent?key=\(apiKey)") else {
            throw GeminiError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw NSError(domain: "GeminiHTTP", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw GeminiError.invalidResponse
        }
        return text
    }

    private func parseAnswer(rawText: String, modelName: String, durationMs: Int) -> AnswerResult {
        let cleaned = rawText
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let data = cleaned.data(using: .utf8),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let answer = (obj["correctAnswer"] as? String) ?? cleaned
            let explanation = (obj["explanation"] as? String) ?? ""
            let shapeStr = ((obj["optionShape"] as? String) ?? "UNKNOWN").uppercased()
            let shape = OptionShape(rawValue: shapeStr) ?? .unknown
            return AnswerResult(
                optionShape: shape,
                directAnswer: answer,
                explanation: explanation,
                modelUsed: modelName,
                durationMs: durationMs
            )
        }

        return AnswerResult(
            optionShape: .unknown,
            directAnswer: cleaned,
            explanation: "",
            modelUsed: modelName,
            durationMs: durationMs
        )
    }

    private func compressImage(_ image: UIImage) -> Data? {
        let maxDim: CGFloat = 1080
        let size = image.size
        let longest = max(size.width, size.height)
        let targetImage: UIImage
        if longest > maxDim {
            let scale = maxDim / longest
            let newSize = CGSize(width: size.width * scale, height: size.height * scale)
            let renderer = UIGraphicsImageRenderer(size: newSize)
            targetImage = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
        } else {
            targetImage = image
        }
        return targetImage.jpegData(compressionQuality: 0.75)
    }
}
