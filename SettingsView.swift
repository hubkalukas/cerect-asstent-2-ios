import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @State private var customKeyInput = ""
    @State private var savedBanner = false

    var body: some View {
        NavigationStack {
            List {
                Section("Modelový Pool (Bez umělých limitů)") {
                    ForEach(Array(GeminiService.candidateModels.enumerated()), id: \.offset) { index, model in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(model.name)
                                    .font(.body.weight(.semibold))
                                Text(index == 0 ? "Primární model (nejrychlejší)" : "Automatická záloha #\(index)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("● OK")
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.15))
                                .foregroundColor(.green)
                                .clipShape(Capsule())
                        }
                    }
                }

                Section("Gemini API klíč") {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                        Text("Systémový API klíč je nakonfigurován a chráněn.")
                            .font(.subheadline)
                    }

                    SecureField("Volitelný vlastní API klíč (přepsání)...", text: $customKeyInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button("Uložit vlastní klíč") {
                        store.saveCustomApiKey(customKeyInput)
                        customKeyInput = ""
                        savedBanner = true
                    }

                    if savedBanner {
                        Text("Uloženo. Klíč není nikde zobrazován.")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }

                Section("O aplikaci") {
                    LabeledContent("Název", value: "cerect asstent 2 (iOS)")
                    LabeledContent("Verze", value: "2.0")
                    LabeledContent("Timeout", value: "7 s / model")
                }
            }
            .navigationTitle("Nastavení")
        }
    }
}
