import SwiftData
import SwiftUI

@main
struct pCalenderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: CalendarEvent.self)
    }
}

