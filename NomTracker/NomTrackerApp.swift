import SwiftData
import SwiftUI

@main
struct NomTrackerApp: App {
    let container: ModelContainer

    init() {
        #if DEBUG
        // `-sampleData` launches with an in-memory store full of sample entries.
        if CommandLine.arguments.contains("-sampleData") {
            container = PreviewData.makeContainer()
            return
        }
        #endif
        do {
            container = try ModelContainer(for: Macro.self, SavedFood.self, FoodEntry.self)
        } catch {
            fatalError("Could not open the NomTracker database: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    @State private var tab = Self.initialTab

    var body: some View {
        TabView(selection: $tab) {
            TodayView()
                .tabItem { Label("Log", systemImage: "fork.knife") }
                .tag(0)
            ProgressScreen()
                .tabItem { Label("Progress", systemImage: "chart.bar.xaxis") }
                .tag(1)
            FoodsView()
                .tabItem { Label("Foods", systemImage: "list.bullet.rectangle") }
                .tag(2)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(3)
        }
        .task { SeedData.seedIfNeeded(context) }
    }

    private static var initialTab: Int {
        #if DEBUG
        // `-tab N` opens a specific tab, for screenshots.
        return UserDefaults.standard.integer(forKey: "tab")
        #else
        return 0
        #endif
    }
}

#Preview {
    RootView()
        .modelContainer(PreviewData.makeContainer())
}
