//
//  Todo.swift
//  TodoMenuBar
//
//  Created by Marc J. Greenberg on 11/8/24.
//


import Foundation

struct Todo: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var created: Date?
    var completed: Date?
    var due: Date?

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.created = Date()
        self.completed = nil
        self.due = nil
    }
}
