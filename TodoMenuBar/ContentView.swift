import SwiftUI
import AppKit

struct ContentView: View {
    @State private var todos: [Todo] = []
    @State private var newTodoTitle: String = ""
    @State private var showMenu = false
    @State private var selectedTodoId: UUID? = nil
    @State private var isEditing = false
    @State private var editedTodoTitle: String = ""
    private let appVersion = "1.1.0"
    
    init() {
        let loadedTodos = loadTodos()
        _todos = State(initialValue: loadedTodos)
    }
    
    fileprivate func socialButton(imageName: String, url: String) -> some View {
        return Button(action: { NSWorkspace.shared.open(URL(string: url)!) }) {
            Image(imageName).resizable().scaledToFit().frame(width: 16, height: 16)
        }.buttonStyle(.plain)
    }
    
    var body: some View {
        VStack {

            HStack {
                TextField("New todo", text: $newTodoTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: addTodo) {
                    Image(systemName: "plus.circle.fill")
                }
                
                Button {
                    showMenu.toggle()
                } label: {
                    Image(systemName: "chevron.down.circle")
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .popover(isPresented: $showMenu, arrowEdge: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Button(action: deleteAllAndClose) {
                            Label("Delete All", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)

                        Button(action: archiveCompleted) {
                            Label("Archive Completed", systemImage: "archivebox")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)

                        Divider()

                        Button(action: openDataDirectory) {
                            Label("Data Files", systemImage: "folder")
                        }
                        .buttonStyle(.plain)

                        Divider()
                        
                        Button(action: showAbout) {
                            Label("About", systemImage: "info.circle")
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: showHelp) {
                            Label("Help", systemImage: "questionmark.circle")
                        }
                        .buttonStyle(.plain)
                        

                        Button(action: quitApp) {
                            Label("Quit", systemImage: "power")
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(8)
                }
            }
            .padding()

            HStack(spacing: 12) {
                socialButton(imageName: "github", url: "https://github.com")
                socialButton(imageName: "linkedin", url: "https://linkedin.com")
                socialButton(imageName: "chatgpt", url: "https://chat.openai.com")
                socialButton(imageName: "claude", url: "https://claude.ai")
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)

            List(selection: $selectedTodoId) {
                ForEach(todos) { todo in

                    HStack {
                        if selectedTodoId == todo.id {
                           Image(systemName: "line.3.horizontal")
                            .foregroundColor(.white)
                            .opacity(0.8)
                            .font(.system(size: 14, weight: .bold))
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
                            Text(todo.title)
                                .strikethrough(todo.isCompleted)
                                .foregroundColor(selectedTodoId == todo.id ? .secondary : .primary)
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
        alert.accessoryView = NSTextField(labelWithString: alert.informativeText)
        (alert.accessoryView as? NSTextField)?.alignment = .left
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
    
}
