import SwiftUI

enum OptionShape: String, Codable, CaseIterable {
    case triangle = "TRIANGLE"
    case diamond = "DIAMOND"
    case circle = "CIRCLE"
    case square = "SQUARE"
    case unknown = "UNKNOWN"

    var symbol: String {
        switch self {
        case .triangle: return "▲"
        case .diamond: return "◆"
        case .circle: return "●"
        case .square: return "■"
        case .unknown: return "✦"
        }
    }

    var emoji: String {
        switch self {
        case .triangle: return "🔴 ▲"
        case .diamond: return "🔵 ◆"
        case .circle: return "🟡 ●"
        case .square: return "🟢 ■"
        case .unknown: return "⚡"
        }
    }

    var colorNameCz: String {
        switch self {
        case .triangle: return "Červená"
        case .diamond: return "Modrá"
        case .circle: return "Žlutá"
        case .square: return "Zelená"
        case .unknown: return "Odpověď"
        }
    }

    var color: Color {
        switch self {
        case .triangle: return Color(red: 0.89, green: 0.11, blue: 0.24)
        case .diamond: return Color(red: 0.07, green: 0.41, blue: 0.81)
        case .circle: return Color(red: 0.85, green: 0.62, blue: 0.0)
        case .square: return Color(red: 0.15, green: 0.54, blue: 0.05)
        case .unknown: return Color(red: 0.31, green: 0.27, blue: 0.90)
        }
    }

    var hapticCount: Int {
        switch self {
        case .triangle: return 1
        case .diamond: return 2
        case .circle: return 3
        case .square: return 4
        case .unknown: return 1
        }
    }
}

struct AnswerResult: Codable, Identifiable {
    let id: UUID
    let optionShape: OptionShape
    let directAnswer: String
    let explanation: String
    let modelUsed: String
    let durationMs: Int
    let timestamp: Date

    init(
        id: UUID = UUID(),
        optionShape: OptionShape,
        directAnswer: String,
        explanation: String,
        modelUsed: String,
        durationMs: Int,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.optionShape = optionShape
        self.directAnswer = directAnswer
        self.explanation = explanation
        self.modelUsed = modelUsed
        self.durationMs = durationMs
        self.timestamp = timestamp
    }
}

struct QuizQuestion: Identifiable {
    let id = UUID()
    let category: String
    let question: String
    let options: [(OptionShape, String)]
}
