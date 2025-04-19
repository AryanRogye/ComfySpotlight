//
//  AppDelegate.swift
//  ComfyNotes
//
//  Created by Aryan Rogye on 4/18/25.
//

import AppKit
import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleInteraction = Self("toggleInteraction")
}

class FloatingPanel: NSPanel {
    var isInteractionEnabled = true
    
    override var canBecomeKey: Bool {
        return isInteractionEnabled
    }
    
    override var canBecomeMain: Bool {
        return isInteractionEnabled
    }
}

public class AppDelegate: NSObject, NSApplicationDelegate {
    var window: FloatingPanel!
    public func applicationDidFinishLaunching(_ notification: Notification) {
        
        KeyboardShortcuts.setShortcut(.init(.one, modifiers: [.command, .shift]), for: .toggleInteraction)

        let contentView = MySwiftUIView()

        window = FloatingPanel(
            contentRect: NSRect(x: 200, y: 200, width: 600, height: 600),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        // 3. Configure your window rules
        window.level = .screenSaver // ➡️ Stays above everything
        window.backgroundColor = .gray.withAlphaComponent(0.3)
        window.isOpaque = false // ➡️ No background fill
        window.hasShadow = false // ➡️ No drop shadow
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary] // ➡️ Appears in all Spaces
        window.isMovableByWindowBackground = true // ➡️ Drag around easily
        window.ignoresMouseEvents = false // ➡️ (important for your cursor tracking later)
        
        // 4. Set the SwiftUI view into the panel
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        
        KeyboardShortcuts.onKeyUp(for: .toggleInteraction) {
            self.window.ignoresMouseEvents.toggle()
            print("Interaction mode toggled: \(self.window.ignoresMouseEvents)")
        }
    }
}

struct MySwiftUIView: View {
    @State private var text: String = ""
    var body: some View {
        ZStack {
            TransparentTextEditor(text: $text)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(10)
        }
        .background(Color.clear)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TransparentTextEditor: NSViewRepresentable {
    @Binding var text: String // Binds to the text state in the SwiftUI view

    // Creates the Coordinator instance
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // Creates the NSScrollView and NSTextView
    func makeNSView(context: Context) -> NSScrollView {
        // Create the scroll view
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = false // Hide vertical scroller
        scrollView.hasHorizontalScroller = false // Hide horizontal scroller
        scrollView.drawsBackground = false // Make scroll view background transparent
        scrollView.backgroundColor = .clear // Explicitly set background color to clear

        // Create the text view
        let textView = NSTextView()
        textView.isEditable = true // Allow editing
        textView.isSelectable = true // Allow text selection
        textView.drawsBackground = false // Make text view background transparent
        textView.backgroundColor = .clear // Explicitly set background color to clear
        textView.textColor = NSColor.white // Set text color
        textView.font = NSFont.systemFont(ofSize: 18) // Set font
        textView.isRichText = false // Use plain text
        textView.delegate = context.coordinator // Set the delegate for text changes
        textView.string = text // Initialize with the bound text
        // Allow text view to grow vertically automatically
        textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.autoresizingMask = [.width] // Ensure it resizes horizontally with the scroll view

        // Set the text view as the document view of the scroll view
        scrollView.documentView = textView
        return scrollView
    }

    // Updates the NSTextView when the bound text changes
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        // Access the text view within the scroll view
        if let textView = scrollView.documentView as? NSTextView {
            // Update the text view's content only if it differs from the binding
            if textView.string != text {
                // Preserve current selection if possible
                let selectedRange = textView.selectedRange()
                textView.string = text
                textView.setSelectedRange(selectedRange) // Try to restore selection
            }
        }
    }

    // Coordinator class to handle NSTextViewDelegate callbacks
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TransparentTextEditor // Reference to the parent struct

        init(_ parent: TransparentTextEditor) {
            self.parent = parent
        }

        // Called when the text in the NSTextView changes
        func textDidChange(_ notification: Notification) {
            // Ensure the notification object is an NSTextView
            guard let textView = notification.object as? NSTextView else { return }
            // Update the bound text property in the parent SwiftUI view
            parent.text = textView.string
        }
    }
}
