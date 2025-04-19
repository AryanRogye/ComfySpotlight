//
//  Notes.swift
//  ComfyNotes
//
//  Created by Aryan Rogye on 4/19/25.
//

import Foundation

struct Note: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var content: String
}
