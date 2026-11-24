import SwiftUI
import UIKit

struct HistoryView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        NavigationStack {
            Group {
                if store.history.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 42))
                            .foregroundColor(.secondary)
                        Text("Zatím žádná historie")
                            .font(.headline)
                        Text("Vyřešené kvízy a skeny obrazovky se uloží sem.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(store.history) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(item.timestamp.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Button {
                                        UIPasteboard.general.string = item.directAnswer
                                    } label: {
                                        Image(systemName: "doc.on.doc")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.borderless)
                                }

                                HStack(spacing: 8) {
                                    if item.optionShape != .unknown {
                                        Text("\(item.optionShape.symbol) \(item.optionShape.colorNameCz)")
                                            .font(.caption.bold())
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(item.optionShape.color)
                                            .foregroundColor(.white)
                                            .clipShape(Capsule())
                                    }
                                    Text(item.directAnswer)
                                        .font(.headline)
                                }

                                if !item.explanation.isEmpty {
                                    Text(item.explanation)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                Text("⚡ \(item.modelUsed) • \(String(format: "%.1fs", Double(item.durationMs) / 1000.0))")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Historie nápovědy")
            .toolbar {
                if !store.history.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Vymazat", role: .destructive) {
                            store.clearHistory()
                        }
                    }
                }
            }
        }
        .onAppear {
            store.reloadHistory()
        }
    }
}
