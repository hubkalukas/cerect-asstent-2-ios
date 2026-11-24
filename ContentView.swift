import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        TabView {
            OverlayView()
                .tabItem {
                    Label("Asistent", systemImage: "square.stack.3d.up.fill")
                }

            QuizSandboxView()
                .tabItem {
                    Label("Cvičný kvíz", systemImage: "brain.head.profile")
                }

            HistoryView()
                .tabItem {
                    Label("Historie", systemImage: "clock.arrow.circlepath")
                }

            SettingsView()
                .tabItem {
                    Label("Nastavení", systemImage: "gearshape.fill")
                }
        }
        .tint(Color(red: 0.31, green: 0.27, blue: 0.90))
    }
}
