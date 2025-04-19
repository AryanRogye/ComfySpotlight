//
//  NotesStorage.swift
//  ComfyNotes
//
//  Created by Aryan Rogye on 4/19/25.
//

import Foundation

final class NotesStorage: ObservableObject {
    static let shared = NotesStorage()
    
    @Published var notes: [Note] = []
    
    private let notesURL: URL = {
        let fm = FileManager.default
        let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appendingPathComponent("ComfyNotes")
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("notes.json")
    }()
    
    private init() {
        load()
    }
    
    func load() {
        if let data = try? Data(contentsOf: notesURL),
           let decoded = try? JSONDecoder().decode([Note].self, from: data) {
            notes = decoded
        }
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(notes) {
            try? data.write(to: notesURL)
        }
    }
    
    func addMockNotes() {
        notes = [
            Note(name: "Build ComfyNotes MVP", content: "Finish the basic structure 🛸"),
            Note(name: "Workout Routine", content: "Pushups, Pullups, Squats"),
            Note(name: "Ideas", content: "Build Raycast clone one day"),
            Note(name: "Daily Log", content: "Today I fought SwiftData and won 😂")
        ]
        save()
    }
}
