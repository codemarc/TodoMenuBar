import SwiftUI
import AppKit

struct ContentView: View {
    @State private var todos: [Todo] = []
    @State private var newTodoTitle: String = ""
    @State private var showMenu = false
    private let appVersion = "1.0.1"
    
    init() {
        let loadedTodos = loadTodos()
        _todos = State(initialValue: loadedTodos)
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
            
            List {
                ForEach(todos) { todo in
                    HStack {
                        Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(todo.isCompleted ? .green : .gray)
                            .onTapGesture {
                                toggleTodo(todo)
                            }
                        
                        Text(todo.title)
                            .strikethrough(todo.isCompleted)
                        
                        Spacer()
                        
                        // Removed the minus circle fill button
                    }
                }
                .onDelete(perform: deleteTodos)
            }
        }
        .frame(width: 300, height: 400)
    }
    
    private func addTodo() {
        guard !newTodoTitle.isEmpty else { return }
        todos.append(Todo(title: newTodoTitle))
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
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func getTodosFileURL() -> URL {
        getDocumentsDirectory().appendingPathComponent("todos.json")
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
    
}
