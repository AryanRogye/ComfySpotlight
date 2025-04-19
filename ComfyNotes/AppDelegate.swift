//
//  AppDelegate.swift
//  ComfyNotes
//
//  Created by Aryan Rogye on 4/18/25.
//

import AppKit
import SwiftUI
import KeyboardShortcuts
import Carbon.HIToolbox
import Foundation

extension KeyboardShortcuts.Name {
    static let toggleInteraction = Self("toggleInteraction")
}

class FloatingPanel: NSPanel {
    var isInteractionEnabled = true
    var onClose: (() -> Void)?
    
    override var canBecomeKey: Bool {
        return isInteractionEnabled
    }
    
    override var canBecomeMain: Bool {
        return isInteractionEnabled
    }
    override func resignKey() {
        super.resignKey()
        onClose?()
        close()
    }
}

public class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate!

    var window: FloatingPanel!
    var searchWindow: FloatingPanel!
    var launcherHotKeyRef: EventHotKeyRef?
    
    var isSearchWindowOpen: Bool = false
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        /// Register Global Hotkey for "Start of App": The SearchView
        registerGlobalHotkey()
        /// This is for closing the sesarch win
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if self.isSearchWindowOpen {
                if event.keyCode == 53 {
                    self.closeSearchWindow()
                }
            }
            return event;
        }

        
        KeyboardShortcuts.setShortcut(.init(.one, modifiers: [.command, .shift]), for: .toggleInteraction)
        
        
        KeyboardShortcuts.onKeyUp(for: .toggleInteraction) {
            guard let _ = self.window else { return }
            self.window.ignoresMouseEvents.toggle()
            print("Interaction mode toggled: \(self.window.ignoresMouseEvents)")
        }
    }
    
    
    func openNote(note: Binding<Note>) {
        let noteView = MySwiftUIView(note: note)

        let noteWindow = FloatingPanel(
            contentRect: NSRect(x: 300, y: 300, width: 400, height: 400),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        noteWindow.level = .screenSaver // ➡️ Stays above everything
        noteWindow.backgroundColor = .gray.withAlphaComponent(0.3)
        noteWindow.isOpaque = false // ➡️ No background fill
        noteWindow.hasShadow = false // ➡️ No drop shadow
        noteWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary] // ➡️ Appears in all Spaces
        noteWindow.isMovableByWindowBackground = true // ➡️ Drag around easily
        noteWindow.ignoresMouseEvents = false
        
        noteWindow.contentView = NSHostingView(rootView: noteView)
        noteWindow.makeKeyAndOrderFront(nil)
    }
    
    func openSearchLauncher() {
        NotesStorage.shared.addMockNotes()

        if searchWindow != nil {
            if searchWindow.isVisible {
                searchWindow.makeKeyAndOrderFront(nil)
                return
            }
        }

        // 1) Build your SwiftUI search view
        let searchBar = SearchBar()

        // 2) Wrap in a hosting controller
        let hostingController = NSHostingController(rootView: searchBar)

        // 3) Create the panel at any dummy size
        searchWindow = FloatingPanel(
          contentRect: .zero,
          styleMask: [.borderless, .nonactivatingPanel],
          backing: .buffered,
          defer: false
        )
        /// Set its on close value to close it
        searchWindow.onClose = { [weak self] in
            self?.isSearchWindowOpen = false
        }

        // 4) Re‑apply your "always on top" rules
        searchWindow.level = .screenSaver
        searchWindow.backgroundColor = .windowBackgroundColor.withAlphaComponent(0)
        searchWindow.isOpaque = false
        searchWindow.hasShadow = true
        searchWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        // …etc…

        // 5) Embed the controller
        searchWindow.contentViewController = hostingController

        // 6) Let it layout and grab the true size
        hostingController.view.layout()
        let size = hostingController.view.fittingSize

        // 7) Center & resize the panel
        if let screen = NSScreen.main?.frame {
          let origin = CGPoint(
            x: (screen.width  - size.width)  / 2,
            y: (screen.height - size.height) / 2
          )
          searchWindow.setFrame(CGRect(origin: origin, size: size), display: true)
        }

        // 8) Show it
        searchWindow.makeKeyAndOrderFront(nil)
    }
        
    
    
    func registerGlobalHotkey() {
        let modifierKeys: UInt32 = UInt32(controlKey | shiftKey)
        let keyCode: UInt32 = 0x31 // spacebar

        let eventHotKeyID = EventHotKeyID(signature: OSType("cmfy".fourCharCodeValue), id: 1)

        RegisterEventHotKey(
            keyCode,
            modifierKeys,
            eventHotKeyID,
            GetApplicationEventTarget(),
            0,
            &launcherHotKeyRef
        )
        installHotkeyHandler()
    }
    
    private func installHotkeyHandler() {
        let eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(
            GetApplicationEventTarget(),
            hotkeyCallback,
            1,
            [eventType],
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            nil
        )
    }
    
    private func closeSearchWindow() {
        self.searchWindow.close()
        self.isSearchWindowOpen = false
    }

    private let hotkeyCallback: EventHandlerUPP = { (_, eventRef, userData) in
        var hotKeyID = EventHotKeyID()
        GetEventParameter(eventRef, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout.size(ofValue: hotKeyID), nil, &hotKeyID)

        if hotKeyID.signature == OSType("cmfy".fourCharCodeValue) {
            if let userData = userData {
                let delegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
                /// Have the search window open up
                delegate.isSearchWindowOpen = true
                delegate.openSearchLauncher()
            }
        }

        return noErr
    }
}

extension String {
    var fourCharCodeValue: FourCharCode {
        var result: FourCharCode = 0
        for char in utf16 {
            result = (result << 8) + FourCharCode(char)
        }
        return result
    }
}

struct MySwiftUIView: View {
    @Binding var note: Note
    var body: some View {
        ZStack {
            TransparentTextEditor(text: $note.content)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(10)
        }
        .background(Color.clear)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
