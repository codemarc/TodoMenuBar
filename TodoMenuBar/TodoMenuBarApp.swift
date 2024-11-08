import SwiftUI

@main
struct TodoMenuBarApp: App {
    var body: some Scene {
        MenuBarExtra("Todo List", systemImage: "checklist") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
