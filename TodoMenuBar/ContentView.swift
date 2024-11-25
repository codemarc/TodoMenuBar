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

    @State private var genaiURL: String = UserDefaults.standard.string(forKey: "genaiURL") ?? "https://ai.com"
    @State private var githubURL: String = UserDefaults.standard.string(forKey: "githubURL") ?? "https://github.com"
    @State private var linkedinURL: String = UserDefaults.standard.string(forKey: "linkedinURL") ?? "https://linkedin.com"
    @State private var twitterURL: String = UserDefaults.standard.string(forKey: "twitterURL") ?? "https://twitter.com"
    @State private var instagramURL: String = UserDefaults.standard.string(forKey: "instagramURL") ?? "https://instagram.com"
    @State private var tiktokURL: String = UserDefaults.standard.string(forKey: "tiktokURL") ?? "https://tiktok.com"
    @State private var investURL: String = UserDefaults.standard.string(forKey: "investURL") ?? "https://client.schwab.com/app/accounts/positions/#/"
    @State private var cmcURL: String = UserDefaults.standard.string(forKey: "cmcURL") ?? "https://codemarc.net"


    private let appVersion = "1.1.5"

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
        return HStack(spacing: 12) {
        ToolbarButton(imageName: "cmc", url: cmcURL, tooltip: "CodeMarc")
        ToolbarButton(imageName: "chatgpt", url: genaiURL, tooltip: "ChatGPT")
        ToolbarButton(imageName: "github", url: githubURL, tooltip: "GitHub")
        ToolbarButton(imageName: "linkedin", url: linkedinURL, tooltip: "LinkedIn")
        ToolbarButton(imageName: "twitter", url: twitterURL, tooltip: "Twitter")
        ToolbarButton(imageName: "instagram", url: instagramURL, tooltip: "Instagram")
        ToolbarButton(imageName: "tiktok", url: tiktokURL, tooltip: "TikTok")
        ToolbarButton(imageName: "invest", url: investURL, tooltip: "Investments")
        ToolbarButton(imageName: "outlook", url: "com.microsoft.Outlook", tooltip: "outlook")
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
        alert.messageText = "TodoMenuBar"
        alert.informativeText = "A simple menu bar todo list app\nVersion \(appVersion)\n\nCreated By Marc J. Greenberg (marc@codemarc.net)\nCoded by GenAI (CODY: CHAT)"
        alert.alertStyle = .informational
        alert.icon = NSImage(named: "AppIcon")
        alert.addButton(withTitle: "OK")
        // alert.accessoryView = NSTextField(labelWithString: alert.informativeText)
        // (alert.accessoryView as? NSTextField)?.alignment = .left
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

        let settingsView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 280))
        let sx=20, offset=90,sy=240
        var n=0

        // GenAi URL field
        let genaiLabel = NSTextField(labelWithString: "chatgpt:")
        genaiLabel.frame = NSRect(x: sx, y: sy-(n*30), width: 80, height: 20)
        settingsView.addSubview(genaiLabel)

        let genaiTextField = NSTextField(frame: NSRect(x: offset, y: sy-(n*30), width: 276, height: 20))
        genaiTextField.stringValue = genaiURL
        genaiTextField.placeholderString = "Enter ChatGPT URL"
        settingsView.addSubview(genaiTextField)
        n=n+1

        // GitHub URL field
        let githubLabel = NSTextField(labelWithString: "github:")
        githubLabel.frame = NSRect(x: sx, y: sy-(n*30), width: 80, height: 20)
        settingsView.addSubview(githubLabel)

        let githubTextField = NSTextField(frame: NSRect(x: offset, y: sy-(n*30), width: 276, height: 20))
        githubTextField.stringValue = githubURL
        githubTextField.placeholderString = "Enter GitHub URL"
        settingsView.addSubview(githubTextField)
        n=n+1

        // LinkedIn URL field
        let linkedinLabel = NSTextField(labelWithString: "linkedin:")
        linkedinLabel.frame = NSRect(x: sx, y: sy-(n*30), width: 80, height: 20)
        settingsView.addSubview(linkedinLabel)

        let linkedinTextField = NSTextField(frame: NSRect(x: offset, y: sy-(n*30), width: 276, height: 20))
        linkedinTextField.stringValue = linkedinURL
        linkedinTextField.placeholderString = "Enter LinkedIn URL"
        settingsView.addSubview(linkedinTextField)
        n=n+1

        // Twitter URL field
        let twitterLabel = NSTextField(labelWithString: "twitter:")
        twitterLabel.frame = NSRect(x: sx, y: sy-(n*30), width: 80, height: 20)
        settingsView.addSubview(twitterLabel)

        let twitterTextField = NSTextField(frame: NSRect(x: offset, y: sy-(n*30), width: 276, height: 20))
        twitterTextField.stringValue = twitterURL
        twitterTextField.placeholderString = "Enter Twitter URL"
        settingsView.addSubview(twitterTextField)
        n=n+1

        // Instagram URL field
        let instagramLabel = NSTextField(labelWithString: "insta:")
        instagramLabel.frame = NSRect(x: sx, y: sy-(n*30), width: 80, height: 20)
        settingsView.addSubview(instagramLabel)

        let instagramTextField = NSTextField(frame: NSRect(x: 90, y: sy-(n*30), width: 276, height: 20))
        instagramTextField.stringValue = instagramURL
        instagramTextField.placeholderString = "Enter Instagram URL"
        settingsView.addSubview(instagramTextField)
        n=n+1

        // TikTok URL field
        let tiktokLabel = NSTextField(labelWithString: "tiktok:")
        tiktokLabel.frame = NSRect(x: sx, y: sy-(n*30), width: 80, height: 20)
        settingsView.addSubview(tiktokLabel)

        let tiktokTextField = NSTextField(frame: NSRect(x: offset, y: sy-(n*30), width: 276, height: 20))
        tiktokTextField.stringValue = tiktokURL
        tiktokTextField.placeholderString = "Enter TikTok URL"
        settingsView.addSubview(tiktokTextField)
        n=n+1

        // Invest URL field
        let investLabel = NSTextField(labelWithString: "invest:")
        investLabel.frame = NSRect(x: sx, y: sy-(n*30), width: 80, height: 20)
        settingsView.addSubview(investLabel)

        let investTextField = NSTextField(frame: NSRect(x: offset, y: sy-(n*30), width: 276, height: 20))
        investTextField.stringValue = investURL
        investTextField.placeholderString = "Enter Investing URL"
        settingsView.addSubview(investTextField)
        n=n+1

        alert.accessoryView = settingsView

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            githubURL = githubTextField.stringValue
            linkedinURL = linkedinTextField.stringValue
            twitterURL = twitterTextField.stringValue
            instagramURL = instagramTextField.stringValue
            tiktokURL = tiktokTextField.stringValue

            UserDefaults.standard.set(githubURL, forKey: "githubURL")
            UserDefaults.standard.set(linkedinURL, forKey: "linkedinURL")
            UserDefaults.standard.set(twitterURL, forKey: "twitterURL")
            UserDefaults.standard.set(instagramURL, forKey: "instagramURL")
            UserDefaults.standard.set(tiktokURL, forKey: "tiktokURL")
        }
        showMenu = false
    }

}
