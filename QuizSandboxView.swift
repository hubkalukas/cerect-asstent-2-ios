import SwiftUI

struct QuizSandboxView: View {
    @EnvironmentObject var store: AppStore
    @State private var currentIndex = 0
    @State private var customMode = false
    @State private var customQuestion = ""
    @State private var isAnalyzing = false
    @State private var badgeShape: OptionShape?
    @State private var badgeError = false
    @State private var result: AnswerResult?

    private let sampleQuestions: [QuizQuestion] = [
        QuizQuestion(
            category: "Zeměpis",
            question: "Který z následujících států NESOUSEDÍ s Českou republikou?",
            options: [(.triangle, "Polsko"), (.diamond, "Maďarsko"), (.circle, "Rakousko"), (.square, "Slovensko")]
        ),
        QuizQuestion(
            category: "Matematika",
            question: "Kolik je 17 × 13 − 21?",
            options: [(.triangle, "190"), (.diamond, "200"), (.circle, "210"), (.square, "221")]
        ),
        QuizQuestion(
            category: "Chemie",
            question: "Který prvek má chemickou značku Au?",
            options: [(.triangle, "Stříbro"), (.diamond, "Hliník"), (.circle, "Zlato"), (.square, "Argon")]
        ),
        QuizQuestion(
            category: "Hlavní města",
            question: "Které město je hlavním městem Francie?",
            options: [(.triangle, "Paříž"), (.diamond, "Londýn"), (.circle, "Řím"), (.square, "Madrid")]
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Režim", selection: $customMode) {
                        Text("Vzorové otázky").tag(false)
                        Text("Vlastní text").tag(true)
                    }
                    .pickerStyle(.segmented)

                    if customMode {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Zadej vlastní otázku:")
                                .font(.subheadline.bold())
                            TextEditor(text: $customQuestion)
                                .frame(height: 120)
                                .padding(8)
                                .background(Color(.tertiarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        questionCard
                    }

                    Button {
                        Task { await runQuizScan() }
                    } label: {
                        HStack {
                            if isAnalyzing {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(isAnalyzing ? "Analyzuji..." : "Zjistit odpověď")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.31, green: 0.27, blue: 0.90))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isAnalyzing)

                    if let res = result {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("\(res.optionShape.emoji) \(res.directAnswer)")
                                    .font(.headline)
                                Spacer()
                                Text("\(res.durationMs) ms")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if !res.explanation.isEmpty {
                                Text(res.explanation)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Cvičný kvíz")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await runQuizScan() }
                    } label: {
                        Text(badgeError ? "!" : (badgeShape?.symbol ?? "✦"))
                            .font(.headline.bold())
                            .frame(width: 34, height: 34)
                            .background(badgeError ? Color.red : (badgeShape?.color ?? Color(red: 0.31, green: 0.27, blue: 0.90)))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(isAnalyzing)
                }
            }
        }
    }

    private var questionCard: some View {
        let q = sampleQuestions[currentIndex]
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(q.category)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.indigo.opacity(0.15))
                    .foregroundColor(.indigo)
                    .clipShape(Capsule())
                Spacer()
                Text("Otázka \(currentIndex + 1) / \(sampleQuestions.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(q.question)
                .font(.headline)

            ForEach(q.options, id: \.0) { shape, text in
                HStack(spacing: 12) {
                    Text(shape.symbol)
                        .font(.title3.bold())
                        .frame(width: 28)
                    Text(text)
                        .font(.body.weight(.semibold))
                    Spacer()
                }
                .padding(14)
                .background(shape.color)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack {
                Button {
                    currentIndex = (currentIndex - 1 + sampleQuestions.count) % sampleQuestions.count
                    resetState()
                } label: {
                    Image(systemName: "arrow.left.circle.fill").font(.title2)
                }
                Spacer()
                Button {
                    resetState()
                } label: {
                    Image(systemName: "arrow.clockwise.circle").font(.title2)
                }
                Spacer()
                Button {
                    currentIndex = (currentIndex + 1) % sampleQuestions.count
                    resetState()
                } label: {
                    Image(systemName: "arrow.right.circle.fill").font(.title2)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func resetState() {
        badgeShape = nil
        badgeError = false
        result = nil
    }

    private func runQuizScan() async {
        isAnalyzing = true
        badgeError = false
        defer { isAnalyzing = false }

        let promptText: String
        if customMode {
            promptText = customQuestion
        } else {
            let q = sampleQuestions[currentIndex]
            let opts = q.options.map { "\($0.0.symbol) (\($0.0.colorNameCz)): \($0.1)" }.joined(separator: "\n")
            promptText = "\(q.question)\n\(opts)"
        }

        do {
            let res = try await GeminiService.shared.analyze(image: nil, textQuestion: promptText, apiKey: store.activeApiKey())
            result = res
            badgeShape = res.optionShape
            store.addResult(res)
        } catch {
            badgeError = true
            result = AnswerResult(
                optionShape: .unknown,
                directAnswer: "Chyba při analýze",
                explanation: error.localizedDescription,
                modelUsed: "Chyba",
                durationMs: 0
            )
        }
    }
}
