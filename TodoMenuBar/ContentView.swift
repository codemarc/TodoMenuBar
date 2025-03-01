import SwiftUI
import AppKit

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var todos: [Todo] = []
    @State private var newTodoTitle: String = ""
    @State private var showMenu = false
    @State private var selectedTodoId: UUID? = nil
    @State private var isEditing = false
    @State private var editedTodoTitle: String = ""
    @State private var plusButton: NSButton?
    @State private var showingDatePicker = false

    @State private var cmcURL: String = UserDefaults.standard.string(forKey: "cmcURL") ?? "https://codemarc.net"
    @State private var genaiURL: String = UserDefaults.standard.string(forKey: "genaiURL") ?? "https://ai.com"
    @State private var githubURL: String = UserDefaults.standard.string(forKey: "githubURL") ?? "https://github.com"
    @State private var linkedinURL: String = UserDefaults.standard.string(forKey: "linkedinURL") ?? "https://linkedin.com"
    @State private var twitterURL: String = UserDefaults.standard.string(forKey: "twitterURL") ?? "https://twitter.com"
    @State private var instagramURL: String = UserDefaults.standard.string(forKey: "instagramURL") ?? "https://instagram.com"
    @State private var tiktokURL: String = UserDefaults.standard.string(forKey: "tiktokURL") ?? "https://tiktok.com"

    // to get the bundle identifier for an app, use this command in Terminal: osascript -e 'id of app "AppName"'
    // where the AppName is the name of the app you want to get the bundle identifier for
    // "Mail", "Caclulator", or "Calculator Pro • Topbar App",  etc.
    // For example, to get the bundle identifier for Microsoft Outlook, use this command:
    // osascript -e 'id of app "Microsoft Outlook"'
    // com.microsoft.Outlook

    @State private var notesURL: String = UserDefaults.standard.string(forKey: "notesURL") ?? "com.apple.Notes"
    @State private var calcURL: String = UserDefaults.standard.string(forKey: "calcURL") ?? "com.apple.calculator"
    @State private var mailURL: String = UserDefaults.standard.string(forKey: "mailURL") ?? "com.microsoft.Outlook"

    // ThinkOrSwim this is non obvious
    // osascript -e 'id of app "ThinkOrSwim"'
    @State private var investURL: String = UserDefaults.standard.string(forKey: "investURL") ?? "com.install4j.9968-4488-2169-7623.18"


    private let appVersion = "1.1.9"

    init() {
        let loadedTodos = loadTodos()
        _todos = State(initialValue: loadedTodos)
    }


    fileprivate func settingsButton() -> some View {
        return Button(action: showSettings) {
            Image(systemName: "gearshape.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 18, height: 18)
            //.colorMultiply(colorScheme == .dark ? .white : .black) // Adjust color for dark mode
            .onHover { hovering in if hovering { NSCursor.pointingHand.set() } else { NSCursor.arrow.set() }}
        }.buttonStyle(.plain)
    }

	fileprivate func todoControl() -> some View {
		return HStack {
			// On enter key, add the todo
			TextField("New todo", text: $newTodoTitle)
			.padding(2)
			.frame(width: 228, height: 20)
			.textFieldStyle(PlainTextFieldStyle())
			.border(Color.white, width: 0.5)
			.onSubmit {
				addTodo()
				newTodoTitle = ""
			}
			Button(action:{addTodo();newTodoTitle = ""}) {
				Image(systemName: "plus.circle.fill")
			}
		}
	}

	fileprivate func todoMenu() -> some View {
		return  Menu {
			Button(action: showAbout) {Label("About", systemImage: "info.circle")}
			Divider()
			Button(action: showSettings) {Label("Settings", systemImage: "gearshape.fill")}
			Button(action: openDataDirectory) {Label("Data Files", systemImage: "folder")}
			Divider()
			Button(action: deleteAllAndClose) {Label("Delete All", systemImage: "trash").foregroundColor(.red)}
			Button(action: archiveCompleted) {Label("Archive Completed", systemImage: "archivebox").foregroundColor(.blue)}
			Divider()
			Button(action: showHelp) { Label("Help", systemImage: "questionmark.circle") }
			Button(action: quitApp) {  Label("Quit", systemImage: "power") }
		} label: {
			Image(systemName: "line.3.horizontal")
			.frame(width: 18, height: 18)
			.background(Color(.windowBackgroundColor))

		}
		.menuStyle(BorderlessButtonMenuStyle())
		.menuIndicator(.hidden)
		.padding(0)
	}

	fileprivate func todoMenuBar() -> some View {
		return HStack {
				todoMenu()
				todoControl()
			}.padding(8)
	}


    fileprivate func todoToolBar() -> some View {
        return HStack(spacing: 10) {
            ToolbarButton(imageName: "cmc", url: cmcURL, tooltip: "CodeMarc")
            ToolbarButton(imageName: "invest", url: investURL, tooltip: "Investments")
            ToolbarButton(imageName: "chatgpt", url: genaiURL, tooltip: "ChatGPT")
            ToolbarButton(imageName: "github", url: githubURL, tooltip: "GitHub")
            ToolbarButton(imageName: "linkedin", url: linkedinURL, tooltip: "LinkedIn")
            ToolbarButton(imageName: "twitter", url: twitterURL, tooltip: "Twitter")
            ToolbarButton(imageName: "instagram", url: instagramURL, tooltip: "Instagram")
            ToolbarButton(imageName: "tiktok", url: tiktokURL, tooltip: "TikTok")
            ToolbarButton(imageName: "notes", url: notesURL, tooltip: "Notes")
            ToolbarButton(imageName: "calc", url: calcURL, tooltip: "Calculator")
            ToolbarButton(imageName: "outlook", url: mailURL, tooltip: "Mail")
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

	fileprivate func todoList() -> some View {
		return  List(selection: $selectedTodoId) {
                ForEach(todos) { todo in

                    HStack {
                        if selectedTodoId == todo.id {
                           Image(systemName: "line.3.horizontal")
                            .foregroundColor(.white)
                            .opacity(0.8)
                            .font(.system(size: 14, weight: .bold))
                            .onTapGesture(count: 2) { // Double tap gesture
                                if let index = todos.firstIndex(where: { $0.id == selectedTodoId }) {
                                            if todos[index].due != nil {
                                                // Remove due date if it exists
                                                todos[index].due = nil
                                            } else {
                                                // Show date picker to set due date
                                                showingDatePicker = true
                                            }
                                            saveTodos()
                                        }
                            }
                            .popover(isPresented: $showingDatePicker) {
                                DatePicker("Due Date", selection: Binding(
                                get: { todos.first(where: { $0.id == selectedTodoId })?.due ?? Date() },
                                set: { newDate in
                                    if let index = todos.firstIndex(where: { $0.id == selectedTodoId }) {
                                        todos[index].due = newDate
                                        saveTodos()
                                    }
                                }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                            )
                                .datePickerStyle(.graphical)
                            .padding()

                            }

                        }

                        Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(todo.isCompleted ? .green : .gray)
                            .onTapGesture {
                                toggleTodo(todo)
                            }

                        if isEditing && selectedTodoId == todo.id {
                            TextField("Edit todo", text: $editedTodoTitle, onCommit: {
                                updateTodoTitle(todo)
                            })
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(.white)
                        } else {
                            if(todo.due != nil) {
                                Text(todo.title + "\n" + (todo.due?.formatted(date: .complete, time: .shortened) ?? ""))
                                .font(.system(size: 11))
                                .strikethrough(todo.isCompleted)
                                .foregroundColor(selectedTodoId == todo.id ? .secondary : .primary)
                            } else {
                                Text(todo.title)
                                .strikethrough(todo.isCompleted)
                                .foregroundColor(selectedTodoId == todo.id ? .secondary : .primary)
                            }


                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedTodoId == todo.id && !isEditing {
                            isEditing = true
                            editedTodoTitle = todo.title
                        } else {
                            selectedTodoId = todo.id
                            isEditing = false
                        }
                    }
                }
                .onMove(perform: moveTodos)
                .onDelete(perform: deleteTodos)
            }
	}

	var body: some View {
		VStack {
			todoMenuBar()
			todoToolBar()
			todoList()
        }
        .frame(width: 330, height: 330)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedTodoId = nil
            isEditing = false
        }
    }

    private func moveTodos(from source: IndexSet, to destination: Int) {
        todos.move(fromOffsets: source, toOffset: destination)
        saveTodos()
    }

    private func addTodo() {
        guard !newTodoTitle.isEmpty else { return }
        todos.insert(Todo(title: newTodoTitle), at: 0)
        newTodoTitle = ""
        saveTodos()
    }

    private func toggleTodo(_ todo: Todo) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index].isCompleted.toggle()
            if todos[index].isCompleted {
                todos[index].completed = Date()
            } else {
                todos[index].completed = nil
            }
            saveTodos()
        }
    }

    private func deleteTodo(_ todo: Todo) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos.remove(at: index)
            saveTodos()
        }
    }

    private func deleteTodos(at offsets: IndexSet) {
        todos.remove(atOffsets: offsets)
        saveTodos()
    }

    private func deleteAllAndClose() {
        todos.removeAll()
        showMenu = false
        saveTodos()
    }

    private func archiveCompleted() {
        let completedTodos = todos.filter { $0.isCompleted }
        let archiveURL = getArchiveFileURL()

        do {
            let existingData = try? Data(contentsOf: archiveURL)
            var archivedTodos: [Todo] = []

            if let existingData = existingData {
                archivedTodos = try JSONDecoder().decode([Todo].self, from: existingData)
            }

            archivedTodos.append(contentsOf: completedTodos)
            let archiveData = try JSONEncoder().encode(archivedTodos)
            try archiveData.write(to: archiveURL)

            todos.removeAll(where: { $0.isCompleted })
            showMenu = false
            saveTodos()
        } catch {
            print("Archiving error: \(error)")
        }
    }

    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }


    private func showAbout() {
        // Activate the application first
        NSApp.activate(ignoringOtherApps: true)

        // Create attributed string for credits
        let creditsString = NSMutableAttributedString(string: """
        A simple menu bar todo list app for macOS

        Created By Marc J. Greenberg (marc@codemarc.net)

        For more info visit
        https://codemarc.net/apps/todo
        """)

        // Style the credits text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 4

        // Apply paragraph style to entire text
        creditsString.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: creditsString.length)
        )

        // Apply font to entire text
        creditsString.addAttribute(
            .font,
            value: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
            range: NSRange(location: 0, length: creditsString.length)
        )

        // Make the URL clickable
        let urlString = "https://codemarc.net/apps/todo"
        let urlRange = (creditsString.string as NSString).range(of: urlString)
        creditsString.addAttribute(.link, value: urlString, range: urlRange)
        creditsString.addAttribute(.foregroundColor, value: NSColor.linkColor, range: urlRange)
        creditsString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: urlRange)

        // Use the standard macOS about panel
        NSApplication.shared.orderFrontStandardAboutPanel(
            options: [
                NSApplication.AboutPanelOptionKey.version: appVersion,
                NSApplication.AboutPanelOptionKey.credits: creditsString,
                NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "© 2025 Marc J. Greenberg"
            ]
        )

        // Ensure the About panel comes to front, becomes key, and receives focus
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let aboutWindow = NSApplication.shared.windows.first(where: { $0.title == "About TodoMenuBar" }) {
                aboutWindow.makeKeyAndOrderFront(nil)
                aboutWindow.level = .floating
                aboutWindow.makeKey()
                aboutWindow.makeFirstResponder(nil)
            }
        }

        showMenu = false
    }

    private func showHelp() {
        let alert = NSAlert()
        let helpText =
            "You can add, edit, delete, and mark tasks as completed.\n\n" +
            "To add a new task, type in the text field and click the plus button.\n" +
            "To mark a task as completed, click the circle next to the task.\n" +
            "To delete a task swipe  left on the task.\n" +
            "To delete all tasks, click the trash button in the menu bar."

        alert.messageText = "Todo Help"
        alert.informativeText = "This is a simple todo list app."
        alert.alertStyle = .informational
        alert.icon = NSImage(named: "AppIcon")
        alert.addButton(withTitle: "OK")
        alert.accessoryView = NSTextField(labelWithString: helpText)
        (alert.accessoryView as? NSTextField)?.alignment = .left
        alert.runModal()
        showMenu = false
    }

    private func openDataDirectory() {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: getDocumentsDirectory().path)
        showMenu = false
    }
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func getTodosFileURL() -> URL {
        getDocumentsDirectory().appendingPathComponent("todos.json")
    }

    private func getArchiveFileURL() -> URL {
        getDocumentsDirectory().appendingPathComponent("archive.json")
    }


    private func saveTodos() {
        let fileURL = getTodosFileURL()
        do {
            let data = try JSONEncoder().encode(todos)
            try data.write(to: fileURL)
        } catch {
            print("Saving error: \(error)")
        }
    }

    private func loadTodos() -> [Todo] {
        let fileURL = getTodosFileURL()
        print("Loading todos from: \(fileURL)")

        do {
            let data = try Data(contentsOf: fileURL)
            let loadedTodos = try JSONDecoder().decode([Todo].self, from: data)
            return loadedTodos
        } catch {
            //print("Loading error: \(error.localizedDescription)")
            return []
        }
    }

    private func updateTodoTitle(_ todo: Todo) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index].title = editedTodoTitle
            saveTodos()
            isEditing = false
        }
    }

    private func showSettings() {
        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 350),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        settingsWindow.title = "TodoMenuBar Settings"
        settingsWindow.center()

        let hostingView = NSHostingView(rootView: SettingsView(
            genaiURL: $genaiURL,
            githubURL: $githubURL,
            linkedinURL: $linkedinURL,
            twitterURL: $twitterURL,
            instagramURL: $instagramURL,
            tiktokURL: $tiktokURL,
            investURL: $investURL,
            notesURL: $notesURL,
            calcURL: $calcURL,
            mailURL: $mailURL
        ))

        settingsWindow.contentView = hostingView

        let windowController = NSWindowController(window: settingsWindow)
        windowController.showWindow(nil)

        NSApp.activate(ignoringOtherApps: true)
        settingsWindow.makeKeyAndOrderFront(nil)

        showMenu = false
    }

}

struct SettingsField: View {
    let label: String
    @Binding var text: String
    let key: String
    let isAppField: Bool
    let defaultURL: String
    let defaultApp: String

    @State private var isLookingUpApp = false

    private func lookupAppBundleId(appName: String) {
        isLookingUpApp = true
        let script = "osascript -e 'id of app \"\(appName)\"'"

        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            let pipe = Pipe()

            process.launchPath = "/bin/bash"
            process.arguments = ["-c", script]
            process.standardOutput = pipe
            process.standardError = pipe

            do {
                try process.run()
                process.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let bundleId = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    DispatchQueue.main.async {
                        if !bundleId.contains("execution error") {
                            text = bundleId
                            UserDefaults.standard.set(bundleId, forKey: key)
                        }
                        isLookingUpApp = false
                    }
                }
            } catch {
                print("Error looking up app: \(error)")
                DispatchQueue.main.async {
                    isLookingUpApp = false
                }
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if isAppField {
                    Text(label)
                        .frame(width: 100, alignment: .trailing)
                        .foregroundColor(.blue)
                        .onTapGesture {
                            if let appName = text.components(separatedBy: ".").last {
                                lookupAppBundleId(appName: appName)
                            }
                        }
                        .help("Click to lookup app bundle identifier")
                } else {
                    Text(label)
                        .frame(width: 100, alignment: .trailing)
                }

                if isLookingUpApp {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 20)
                    TextField("Enter app name", text: $text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    TextField(isAppField ? "Enter app name" : "Enter URL", text: $text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: text) { newValue in
                            UserDefaults.standard.set(newValue, forKey: key)
                        }
                }
            }

            HStack {
                Spacer()
                    .frame(width: 100)
                VStack {
                    HStack(spacing: 8) {
                        Text("default ")
                            .foregroundColor(.secondary)
                            .font(.system(size: 11))
                        Button("url") {
                            text = defaultURL
                            UserDefaults.standard.set(defaultURL, forKey: key)
                        }
                        .controlSize(.mini)

                        if isAppField {
                            Button("appid") {
                                text = defaultApp
                                UserDefaults.standard.set(defaultApp, forKey: key)
                            }
                            .controlSize(.mini)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
    }
}

struct SettingsView: View {
    @Binding var genaiURL: String
    @Binding var githubURL: String
    @Binding var linkedinURL: String
    @Binding var twitterURL: String
    @Binding var instagramURL: String
    @Binding var tiktokURL: String
    @Binding var investURL: String
    @Binding var notesURL: String
    @Binding var calcURL: String
    @Binding var mailURL: String
    var body: some View {
        TabView {
            // Developer Category
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Development Tools")
                        .font(.headline)
                        .padding(.bottom, 4)

                    SettingsField(label: "GitHub", text: $githubURL, key: "githubURL",
                                isAppField: false, defaultURL: "https://github.com", defaultApp: "")
                    SettingsField(label: "GenAI", text: $genaiURL, key: "genaiURL",
                                isAppField: false, defaultURL: "https://ai.com", defaultApp: "")

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .background(Color(.windowBackgroundColor))
            .tabItem {
                Label("Developer", systemImage: "chevron.left.forwardslash.chevron.right")
            }

            // Social Category
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Social Media")
                        .font(.headline)
                        .padding(.bottom, 4)

                    SettingsField(label: "LinkedIn", text: $linkedinURL, key: "linkedinURL",
                                isAppField: false, defaultURL: "https://linkedin.com", defaultApp: "")
                    SettingsField(label: "Twitter", text: $twitterURL, key: "twitterURL",
                                isAppField: false, defaultURL: "https://twitter.com", defaultApp: "")
                    SettingsField(label: "Instagram", text: $instagramURL, key: "instagramURL",
                                isAppField: false, defaultURL: "https://instagram.com", defaultApp: "")
                    SettingsField(label: "TikTok", text: $tiktokURL, key: "tiktokURL",
                                isAppField: false, defaultURL: "https://tiktok.com", defaultApp: "")

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .background(Color(.windowBackgroundColor))
            .tabItem {
                Label("Social", systemImage: "person.2.fill")
            }

            // Tools Category
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Productivity Tools")
                        .font(.headline)
                        .padding(.bottom, 4)

                    SettingsField(label: "Notes", text: $notesURL, key: "notesURL",
                                isAppField: true, defaultURL: "https://www.icloud.com/notes", defaultApp: "com.apple.Notes")

                    SettingsField(label: "Calculator", text: $calcURL, key: "calcURL",
                                isAppField: true, defaultURL: "https://www.calculator.net/financial-calculator.html", defaultApp: "com.apple.calculator")

                    SettingsField(label: "Mail", text: $mailURL, key: "mailURL",
                                isAppField: true, defaultURL: "http://outlook.office.com/mail", defaultApp: "com.microsoft.Outlook")

                    SettingsField(label: "Investments", text: $investURL, key: "investURL",
                                isAppField: true, defaultURL: "https://client.schwab.com/app/accounts/positions/#/", defaultApp: "com.install4j.9968-4488-2169-7623.18")
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .background(Color(.windowBackgroundColor))
            .tabItem {
                Label("Tools", systemImage: "wrench.and.screwdriver.fill")
            }
        }
        .frame(width: 450, height: 350)
    }
}
