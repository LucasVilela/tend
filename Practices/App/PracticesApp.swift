import SwiftData
import SwiftUI

@main
struct PracticesApp: App {
    let container: ModelContainer

    init() {
        do {
            #if DEBUG
            // `-sampleData` runs the app on an in-memory store filled with the design's sample data,
            // for checking screens against the screenshots. Debug builds only; real data is untouched.
            if ProcessInfo.processInfo.arguments.contains("-sampleData") {
                container = try SampleData.makeContainer()
                return
            }
            #endif
            container = try AppSchema.makeContainer()
            try TemplateSeeder.seedIfNeeded(container.mainContext)
        } catch {
            fatalError("Could not open the data store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}
