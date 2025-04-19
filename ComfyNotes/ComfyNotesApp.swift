//
//  ComfyNotesApp.swift
//  ComfyNotes
//
//  Created by Aryan Rogye on 4/18/25.
//

import SwiftUI
import AppKit
import KeyboardShortcuts

@main
struct ComfyNotesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
