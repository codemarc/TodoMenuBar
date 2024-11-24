import SwiftUI

fileprivate func outlookButton() -> some View {
        return Button(action: {
            if let outlookURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.Outlook") {
                NSWorkspace.shared.openApplication(at: outlookURL, configuration: NSWorkspace.OpenConfiguration())
            }
        }) {
            Image("outlook")
            .resizable()
            .scaledToFit()
            .padding(0)
            .frame(width: 18, height: 18)
            .onHover { hovering in if hovering { NSCursor.pointingHand.set() } else { NSCursor.arrow.set() }}
        }.buttonStyle(.plain)
    }


struct ToolbarView: View {
    let urls: [String: String]

    var body: some View {
        HStack(spacing: 12) {
            ToolbarButton(imageName: "cmc", url: urls["cmc"] ?? "", tooltip: "Codemarc")
            ToolbarButton(imageName: "chatgpt", url: urls["genai"] ?? "", tooltip: "Codemarc")
            ToolbarButton(imageName: "github", url: urls["github"] ?? "", tooltip: "Codemarc")
            ToolbarButton(imageName: "linkedin", url: urls["linkedin"] ?? "", tooltip: "Codemarc")
            ToolbarButton(imageName: "twitter", url: urls["twitter"] ?? "", tooltip: "Codemarc")
            ToolbarButton(imageName: "instagram", url: urls["instagram"] ?? "", tooltip: "Codemarc")
            ToolbarButton(imageName: "tiktok", url: urls["tiktok"] ?? "", tooltip: "Codemarc")
            ToolbarButton(imageName: "invest", url: urls["invest"] ?? "", tooltip: "Codemarc")
            outlookButton()
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}



var body: some View {
    VStack {
        todoMenuBar()
        ToolbarView(urls: [
            "cmc": cmcURL,
            "genai": genaiURL,
            "github": githubURL,
            "linkedin": linkedinURL,
            "twitter": twitterURL,
            "instagram": instagramURL,
            "tiktok": tiktokURL,
            "invest": investURL
        ])
        todoList()
    }
    .frame(width: 300, height: 400)
    .contentShape(Rectangle())
    .onTapGesture {
        selectedTodoId = nil
        isEditing = false
    }
}
