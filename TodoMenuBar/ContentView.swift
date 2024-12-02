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
    @State private var investURL: String = UserDefaults.standard.string(forKey: "investURL") ?? "https://client.schwab.com/app/accounts/positions/#/"

    // to get the bundle identifier for an app, use this command in Terminal: osascript -e 'id of app "AppName"'
    // where the AppName is the name of the app you want to get the bundle identifier for
    // "Mail", "Caclulator", or "Calculator Pro • Topbar App",  etc.
    // For example, to get the bundle identifier for Microsoft Outlook, use this command:
    // osascript -e 'id of app "Microsoft Outlook"'
    // com.microsoft.Outlook

    @State private var calcURL: String = UserDefaults.standard.string(forKey: "calcURL") ?? "com.apple.calculator"
    @State private var mailURL: String = UserDefaults.standard.string(forKey: "mailURL") ?? "com.microsoft.Outlook"


    private let appVersion = "1.1.7"

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
            .colorMultiply(colorScheme != .dark ? .white : .black) // Adjust color for dark mode
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
        ToolbarButton(imageName: "chatgpt", url: genaiURL, tooltip: "ChatGPT")
        ToolbarButton(imageName: "github", url: githubURL, tooltip: "GitHub")
        ToolbarButton(imageName: "linkedin", url: linkedinURL, tooltip: "LinkedIn")
        ToolbarButton(imageName: "twitter", url: twitterURL, tooltip: "Twitter")
        ToolbarButton(imageName: "instagram", url: instagramURL, tooltip: "Instagram")
        ToolbarButton(imageName: "tiktok", url: tiktokURL, tooltip: "TikTok")
        ToolbarButton(imageName: "invest", url: investURL, tooltip: "Investments")
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
        .frame(width: 300, height: 400)
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
        let alert = NSAlert()
        alert.messageText = "TodoMenuBar v\(appVersion)"
        alert.alertStyle = .informational
        alert.icon = NSImage(named: "AppIcon")
        alert.addButton(withTitle: "OK")

        let informativeText = """

        A simple menu bar todo list app

        Created By Marc J. Greenberg (marc@codemarc.net)
        Coded by GenAI (CODY: CHAT)

        For more info see: https://codemarc.net/apps/todo

        """

        let attributedString = NSMutableAttributedString(string: informativeText)
        let linkRange = (informativeText as NSString).range(of: "https://codemarc.net/apps/todo")
        attributedString.addAttribute(.link, value: "https://codemarc.net/apps/todo", range: linkRange)
        attributedString.addAttribute(.foregroundColor, value: NSColor.white, range: NSRange(location: 0, length: attributedString.length))
        attributedString.addAttribute(.foregroundColor, value: NSColor.green, range: linkRange)
        alert.informativeText = ""

        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
        textView.wantsLayer = true
        textView.layer?.cornerRadius = 5
        textView.isEditable = false
        textView.drawsBackground = true
        textView.backgroundColor = NSColor.black.withAlphaComponent(0.5)
        textView.textStorage?.setAttributedString(attributedString)
        textView.alignment = .center
        alert.accessoryView = textView

        alert.runModal()
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
        let alert = NSAlert()
        alert.messageText = "TodoMenuBar Settings"
        alert.alertStyle = .informational
        alert.icon = NSImage(named: "AppIcon")
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let settingsView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 290))
        let sx=20, offset=90,sy=270
        var n=0

        func setupField(lbl: String, url: String) -> NSTextField {
            let label = NSTextField(labelWithString: lbl)
            label.frame = NSRect(x: sx, y: sy-(n*30), width: 80, height: 20)
            settingsView.addSubview(label)

            let textField = NSTextField(frame: NSRect(x: offset, y: sy-(n*30), width: 276, height: 20))
            textField.stringValue = url
            textField.placeholderString = "Enter URL"
            settingsView.addSubview(textField)
            n=n+1
            return textField
        }

        let genaiTextField = setupField(lbl: "genai:", url: genaiURL)
        let githubTextField = setupField(lbl: "github:", url: githubURL)
        let linkedinTextField = setupField(lbl: "linkedin:", url: linkedinURL)
        let twitterTextField = setupField(lbl: "twitter:", url: twitterURL)
        let instagramTextField = setupField(lbl: "insta:", url: instagramURL)
        let tiktokTextField = setupField(lbl: "tiktok:", url: tiktokURL)
        let investTextField = setupField(lbl: "invest:", url: investURL)
        let calcTextField = setupField(lbl: "calc:", url: calcURL)
        let mailTextField = setupField(lbl: "email:", url: mailURL)


        alert.accessoryView = settingsView

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            githubURL = githubTextField.stringValue
            linkedinURL = linkedinTextField.stringValue
            twitterURL = twitterTextField.stringValue
            instagramURL = instagramTextField.stringValue
            tiktokURL = tiktokTextField.stringValue
            investURL = investTextField.stringValue
            calcURL = calcTextField.stringValue
            mailURL = mailTextField.stringValue

            UserDefaults.standard.set(githubURL, forKey: "githubURL")
            UserDefaults.standard.set(linkedinURL, forKey: "linkedinURL")
            UserDefaults.standard.set(twitterURL, forKey: "twitterURL")
            UserDefaults.standard.set(instagramURL, forKey: "instagramURL")
            UserDefaults.standard.set(tiktokURL, forKey: "tiktokURL")
            UserDefaults.standard.set(investURL, forKey: "investURL")
            UserDefaults.standard.set(calcURL, forKey: "calcURL")
            UserDefaults.standard.set(mailURL, forKey: "mailURL")
        }
        showMenu = false
    }

}
