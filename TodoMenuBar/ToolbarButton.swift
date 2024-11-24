import SwiftUI

struct ToolbarButton: View {
    let imageName: String
    let url: String
    let tooltip: String

    var body: some View {
        Button(action: {
            if imageName == "outlook" {
                if let outlookURL = NSWorkspace.shared.urlForApplication(
                    withBundleIdentifier: "com.microsoft.Outlook")
                {
                    NSWorkspace.shared.openApplication(
                        at: outlookURL, configuration: NSWorkspace.OpenConfiguration())
                }
            } else {
                NSWorkspace.shared.open(URL(string: url)!)
            }
        }) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .help(tooltip)
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
        }
        .buttonStyle(.plain)
    }
}
