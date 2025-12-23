//
//  CodeBlockEditor.swift
//  Notes-app
//
//  Created by Frederik Handberg on 22/12/2025.
//

import AppKit
import SwiftUI
import Highlightr

struct CodeBlockEditor: NSViewRepresentable {
    let content: String
    let language: String
    let isFocused: Bool
    let onSelect: () -> Void
    let onFocus: () -> Void
    let onUnfocus: () -> Void
    let onChange: (String) -> Void
    let onDeleteBlock: (() -> Void)?
    @Binding var lineCount: Int
    @Binding var logicalLineHeights: [CGFloat]
    @Binding var selectedLines: Set<Int>
    
    func makeNSView(context: Context) -> CodeTextView {
        // Use CodeAttributedString for real-time highlighting
        let textStorage = CodeAttributedString()
        textStorage.language = language.isEmpty ? "plaintext" : language
        textStorage.highlightr.setTheme(to: "atom-one-dark")
        
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        let textContainer = NSTextContainer()
        textContainer.widthTracksTextView = true
        textContainer.heightTracksTextView = false
        textContainer.containerSize = NSSize(
            width: 0,
            height: CGFloat.greatestFiniteMagnitude
        )
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)
        
        // Create text view with the text container
        let textView = CodeTextView(frame: .zero, textContainer: textContainer)
        
        // Text view configuration
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.delegate = context.coordinator
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        
        textView.textContainerInset = NSSize(width: 0, height: 0)
        
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        
        // Store reference and set initial content
        context.coordinator.textStorage = textStorage
        
        // Set content using replaceCharacters to properly initialize the text storage
        if !content.isEmpty {
            textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: content)
        }
        
        // Trigger initial line count update after layout
        DispatchQueue.main.async {
            context.coordinator.updateLineCount(for: textView)
        }
        
        return textView
    }
    
    func updateNSView(_ textView: CodeTextView, context: Context) {
        guard let textStorage = context.coordinator.textStorage else { return }
        
        context.coordinator.onSelect = onSelect
        context.coordinator.onFocus = onFocus
        context.coordinator.onUnfocus = onUnfocus
        context.coordinator.onChange = onChange
        context.coordinator.onDeleteBlock = onDeleteBlock
        
        let effectiveLanguage = language.isEmpty ? "plaintext" : language
        if textStorage.language != effectiveLanguage {
            textStorage.language = effectiveLanguage
        }
        
        // Only update if content changed externally (not from typing)
        if !context.coordinator.isEditing && textView.string != content {
            
            let fullRange = NSRange(location: 0, length: textStorage.length)
            textStorage.replaceCharacters(in: fullRange, with: content)
        }
        
        textView.layoutManager?.ensureLayout(for: textView.textContainer!)
        textView.invalidateIntrinsicContentSize()
        
        // Defer line count update to avoid modifying state during view update
        DispatchQueue.main.async {
            context.coordinator.updateLineCount(for: textView)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            language: language,
            lineCount: $lineCount,
            logicalLineHeights: $logicalLineHeights,
            selectedLines: $selectedLines,
            onSelect: onSelect,
            onFocus: onFocus,
            onUnfocus: onUnfocus,
            onChange: onChange,
            onDeleteBlock: onDeleteBlock
        )
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var language: String
        @Binding var lineCount: Int
        @Binding var logicalLineHeights: [CGFloat]
        @Binding var selectedLines: Set<Int>
        var onSelect: () -> Void
        var onFocus: () -> Void
        var onUnfocus: () -> Void
        var onChange: (String) -> Void
        var onDeleteBlock: (() -> Void)?
        var isEditing = false
        
        var textStorage: CodeAttributedString?
        
        init(
            language: String,
            lineCount: Binding<Int>,
            logicalLineHeights: Binding<[CGFloat]>,
            selectedLines: Binding<Set<Int>>,
            onSelect: @escaping () -> Void,
            onFocus: @escaping () -> Void,
            onUnfocus: @escaping () -> Void,
            onChange: @escaping (String) -> Void,
            onDeleteBlock: (() -> Void)?
        ) {
            self.language = language
            self._lineCount = lineCount
            self._logicalLineHeights = logicalLineHeights
            self._selectedLines = selectedLines
            self.onSelect = onSelect
            self.onFocus = onFocus
            self.onUnfocus = onUnfocus
            self.onChange = onChange
            self.onDeleteBlock = onDeleteBlock
            
            super.init()
        }
        
        func textDidBeginEditing(_ notification: Notification) {
            onFocus()
        }
        
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            let selectedRange = textView.selectedRange()
            let text = textView.string
            
            // Calculate which lines are selected
            var newSelectedLines = Set<Int>()
            
            if selectedRange.length > 0 {
                // Multi-character selection - find all affected lines
                let startSubstring = (text as NSString).substring(with: NSRange(location: 0, length: selectedRange.location))
                let startLine = startSubstring.components(separatedBy: "\n").count
                
                let endSubstring = (text as NSString).substring(with: NSRange(location: 0, length: selectedRange.location + selectedRange.length))
                var endLine = endSubstring.components(separatedBy: "\n").count
                
                // Check if selection ends exactly on a newline character
                let endIndex = selectedRange.location + selectedRange.length
                if endIndex > 0 && endIndex <= text.count {
                    let index = text.index(text.startIndex, offsetBy: endIndex - 1)
                    if text[index] == "\n" {
                        // Selection ends on newline, don't count the next line
                        endLine -= 1
                    }
                }
                
                for line in startLine...endLine {
                    newSelectedLines.insert(line)
                }
            } else {
                // Just cursor position - single line
                let substring = (text as NSString).substring(with: NSRange(location: 0, length: selectedRange.location))
                let currentLine = substring.components(separatedBy: "\n").count
                newSelectedLines.insert(currentLine)
            }
            
            selectedLines = newSelectedLines
        }
        
        func textDidEndEditing(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            isEditing = true
            
            let newContent = textView.string
            
            textView.layoutManager?.ensureLayout(for: textView.textContainer!)
            textView.invalidateIntrinsicContentSize()
            
            updateLineCount(for: textView)
            
            onChange(newContent)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.isEditing = false
            }
        }
        
        func updateLineCount(for textView: NSTextView) {
            guard let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer else {
                lineCount = 1
                logicalLineHeights = []
                return
            }
            
            layoutManager.ensureLayout(for: textContainer)
            
            // Count logical lines (separated by \n) not visual lines
            let text = textView.string
            let logicalLineCount = text.isEmpty ? 1 : text.components(separatedBy: "\n").count
            
            // Calculate heights for each logical line
            var heights: [CGFloat] = []
            var currentLogicalLineHeight: CGFloat = 0
            
            // Enumerate all visual line fragments
            let glyphRange = layoutManager.glyphRange(for: textContainer)
            
            layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { rect, usedRect, textContainer, glyphRange, stop in
                // Add this visual fragment's height to the current logical line
                currentLogicalLineHeight += rect.height
                
                // Get the character range for this visual line
                let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
                
                // Get the text content of this visual line
                let lineText = (text as NSString).substring(with: charRange)
                
                if lineText.contains("\n") {
                    heights.append(currentLogicalLineHeight)
                    currentLogicalLineHeight = 0
                }
            }
            
            // Handle last line if it doesn't end with newline
            if currentLogicalLineHeight > 0 {
                heights.append(currentLogicalLineHeight)
            }
            
            // If there's fewer heights than logical lines, fill in the missing ones
            // This happens when lines are empty (just newline characters)
            while heights.count < logicalLineCount {
                let defaultFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
                let defaultLineHeight = layoutManager.defaultLineHeight(for: defaultFont)
                heights.append(defaultLineHeight)
            }
            
            if heights.isEmpty {
                // Calculate default line height from font
                let defaultFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
                let defaultLineHeight = layoutManager.defaultLineHeight(for: defaultFont)
                heights.append(defaultLineHeight)
            }
            
            lineCount = logicalLineCount
            logicalLineHeights = heights
        }
        
        func textView(
            _ textView: NSTextView,
            doCommandBy commandSelector: Selector
        ) -> Bool {
            // Handle ESCAPE key
            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                onUnfocus()
                textView.window?.makeFirstResponder(nil)
                return true
            }
            
            // Handle backspace at position 0 for empty blocks
            if commandSelector == #selector(NSResponder.deleteBackward(_:)) {
                let selectedRange = textView.selectedRange()
                let isEmpty = textView.string.trimmingCharacters(in: .whitespaces).isEmpty
                
                if selectedRange.location == 0 && selectedRange.length == 0 && isEmpty {
                    onDeleteBlock?()
                    return true
                }
            }
            
            return false
        }
    }
}

// Custom NSTextView for intrinsic size
class CodeTextView: NSTextView {
    override var intrinsicContentSize: NSSize {
        guard let layoutManager = layoutManager,
              let textContainer = textContainer
        else {
            return super.intrinsicContentSize
        }
        
        layoutManager.ensureLayout(for: textContainer)
        let usedRect = layoutManager.usedRect(for: textContainer)
        
        return NSSize(
            width: NSView.noIntrinsicMetric,
            height: ceil(usedRect.height)
        )
    }
    
    override func didChangeText() {
        super.didChangeText()
        invalidateIntrinsicContentSize()
    }
}
