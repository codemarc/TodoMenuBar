import SwiftUI

struct ToolbarButton: View {
    let imageName: String
    let url: String
    let tooltip: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: {
            if !url.hasPrefix("http") {
                if let oURL = NSWorkspace.shared.urlForApplication(
                    withBundleIdentifier: url)
                {
                    NSWorkspace.shared.openApplication(
                        at: oURL, configuration: NSWorkspace.OpenConfiguration())
                }
            } else {
                NSWorkspace.shared.open(URL(string: url)!)
            }
        }) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                //.colorMultiply(colorScheme == .dark ? .white : .black)
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
