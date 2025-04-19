//
//  SearchBar.swift
//  ComfyNotes
//
//  Created by Aryan Rogye on 4/19/25.
//

import SwiftUI

struct SearchBar: View {
    @ObservedObject var storage = NotesStorage.shared
    @State private var text: String = ""
    @State private var selectedIndex = -1
    
    var filteredNotes: [Note] {
        if text.isEmpty {
            return storage.notes
        } else {
            return storage.notes.filter { $0.name.localizedCaseInsensitiveContains(text) }
        }
    }
    var maxSelectableIndex: Int { filteredNotes.isEmpty ? 0 : filteredNotes.count - 1 }
    
    var body: some View {
        VStack {
            /// Actual Search Button
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )

                TransparentTextEditor(
                    text: $text,
                    onArrowUp:   { selectedIndex = max(-1, selectedIndex - 1) },
                    onArrowDown: { selectedIndex = min(maxSelectableIndex, selectedIndex + 1) },
                    onReturn: {
                        if filteredNotes.isEmpty {
                            // selected "Add New Note"
                            print("Add a new note")
                        } else if selectedIndex >= 0 && selectedIndex < filteredNotes.count {
                            let selectedNote = filteredNotes[selectedIndex]
                            
                            if let realIndex = storage.notes.firstIndex(where: { $0.id == selectedNote.id }) {
                                let binding = $storage.notes[realIndex]
                                AppDelegate.shared.openNote(note: binding)
                            } else {
                                print("Couldn't find note in storage.notes")
                            }
                        }
                    }
                    
                )
                    .padding(15) // add breathing room for text inside
            }
            .frame(width: 500, height: 60)
            .padding()
            
            /// Search Options
            VStack(alignment: .leading, spacing: 8) {
                if filteredNotes.count != 0 {
                    /// Actual List of Notes
                    ForEach(Array(filteredNotes.enumerated()), id: \.element.id) { idx, note in
                        Text(note.name)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(idx == selectedIndex
                                        ? Color.blue
                                        : Color.red.opacity(0.7))
                            .cornerRadius(6)
                    }
                } else {
                    /// Add Button
                    Button(action: {
                        /// Add new Note Here
                    } ) {
                        Text("Add New Note")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(selectedIndex == 0 ? Color.blue : Color.red.opacity(0.7))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .background(Color.clear)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear{
            if storage.notes.isEmpty {
                storage.addMockNotes()
            }
        }
    }
}

#Preview {
    SearchBar()
}


struct TransparentTextEditor: NSViewRepresentable {
    @Binding var text: String // Binds to the text state in the SwiftUI view
    var onArrowUp:   () -> Void = {}
    var onArrowDown: () -> Void = {}
    var onReturn: () -> Void = {}



    // Creates the Coordinator instance
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class SingleLineTextView: NSTextView {
        var onArrowUp:   ()->Void = {}
        var onArrowDown: ()->Void = {}
        var onReturn: () -> Void = {}

        
        override func keyDown(with event: NSEvent) {
            switch event.keyCode {
            case 126: onArrowUp();   return   // ↑
            case 125: onArrowDown(); return   // ↓
            case 36,76: onReturn()
            default: super.keyDown(with: event)
            }
        }
        override func paste(_ sender: Any?) {
            if let clipboard = NSPasteboard.general.string(forType: .string) {
                let singleLine = clipboard.replacingOccurrences(of: "\n", with: " ")
                self.insertText(singleLine, replacementRange: self.selectedRange())
            }
        }
        
        override func layout() {
            super.layout()
            
            guard let _ = textContainer,
                  let font = self.font else {
                return
            }
            
            let height = bounds.height
            let textHeight = font.ascender - font.descender
            
            let verticalInset = max(0, (height - textHeight) / 2)
            textContainerInset = NSSize(width: 8, height: verticalInset)
        }
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
        let textView = SingleLineTextView()
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
        textView.isHorizontallyResizable = true
        textView.textContainer?.widthTracksTextView = false
        textView.textContainer?.lineBreakMode = .byClipping
        textView.autoresizingMask = [.width] // Ensure it resizes horizontally with the scroll view
        
        textView.onArrowUp = onArrowUp
        textView.onArrowDown = onArrowDown
        textView.onReturn = onReturn

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
