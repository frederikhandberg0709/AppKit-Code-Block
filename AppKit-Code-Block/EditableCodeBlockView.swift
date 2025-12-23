//
//  EditableCodeBlockView.swift
//  Notes-app
//
//  Created by Frederik Handberg on 22/12/2025.
//

import SwiftUI

struct EditableCodeBlockView: View {
    let block: CodeBlock
    let isFocused: Bool
    let onSelect: () -> Void
    let onFocus: () -> Void
    let onUnfocus: () -> Void
    let onChange: (CodeBlock) -> Void
    let onDeleteBlock: (() -> Void)?
    
    @State private var isHovering: Bool = false
    @State private var showLineNumbers: Bool = true
    @State private var selectedLanguage: String
    @State private var actualLineCount: Int = 1
    @State private var logicalLineHeights: [CGFloat] = []
    @State private var selectedLines: Set<Int> = []
    
    private let languages = [
        ("", "Plain Text"),
        ("swift", "Swift"),
        ("python", "Python"),
        ("javascript", "JavaScript"),
        ("typescript", "TypeScript"),
        ("java", "Java"),
        ("cpp", "C++"),
        ("c", "C"),
        ("csharp", "C#"),
        ("go", "Go"),
        ("rust", "Rust"),
        ("ruby", "Ruby"),
        ("php", "PHP"),
        ("kotlin", "Kotlin"),
        ("scala", "Scala"),
        ("sql", "SQL"),
        ("bash", "Bash"),
        ("shell", "Shell"),
        ("json", "JSON"),
        ("xml", "XML"),
        ("html", "HTML"),
        ("css", "CSS"),
        ("markdown", "Markdown"),
    ]
    
    init(
        block: CodeBlock,
        isFocused: Bool,
        onSelect: @escaping () -> Void,
        onFocus: @escaping () -> Void,
        onUnfocus: @escaping () -> Void,
        onChange: @escaping (CodeBlock) -> Void,
        onDeleteBlock: (() -> Void)? = nil
    ) {
        self.block = block
        self.isFocused = isFocused
        self.onSelect = onSelect
        self.onFocus = onFocus
        self.onUnfocus = onUnfocus
        self.onChange = onChange
        self.onDeleteBlock = onDeleteBlock
        self._selectedLanguage = State(initialValue: block.language)
        self._actualLineCount = State(initialValue: max(1, block.content.isEmpty ? 1 : block.content.components(separatedBy: "\n").count))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: Language selector and line numbers toggle
            HStack(spacing: 12) {
                // Language picker
                Menu {
                    ForEach(languages, id: \.0) { lang in
                        Button(lang.1) {
                            selectedLanguage = lang.0
                            var updatedBlock = block
                            updatedBlock.language = lang.0
                            onChange(updatedBlock)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 11))
                        
                        Text(languageDisplayName)
                            .font(.system(size: 12, weight: .medium))
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(isHovering ? 0.08 : 0.05))
                    )
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // Line numbers toggle
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showLineNumbers.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: showLineNumbers ? "list.number" : "list.bullet")
                            .font(.system(size: 11))
                        
                        Text(showLineNumbers ? "Hide Lines" : "Show Lines")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(showLineNumbers ? 0.1 : 0.05))
                    )
                }
                .buttonStyle(.plain)
                .opacity(isHovering || isFocused ? 1 : 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.2))
            
            // Code editor with line numbers
            HStack(alignment: .top, spacing: 0) {
                // Line numbers
                lineNumbersView
                    .opacity(showLineNumbers ? 1 : 0)
                    .frame(width: showLineNumbers ? nil : 0)
                
                // Code editor
                CodeBlockEditor(
                    content: block.content,
                    language: selectedLanguage,
                    isFocused: isFocused,
                    onSelect: onSelect,
                    onFocus: onFocus,
                    onUnfocus: onUnfocus,
                    onChange: { newContent in
                        var updatedBlock = block
                        updatedBlock.content = newContent
                        onChange(updatedBlock)
                    },
                    onDeleteBlock: onDeleteBlock,
                    lineCount: $actualLineCount,
                    logicalLineHeights: $logicalLineHeights,
                    selectedLines: $selectedLines
                )
                .padding(.vertical, 12)
                .padding(.trailing, 12)
                .padding(.leading, showLineNumbers ? 12 : 12)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
    
    private var languageDisplayName: String {
        languages.first(where: { $0.0 == selectedLanguage })?.1 ?? "Plain Text"
    }
    
    private var lineNumbersView: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(Array(logicalLineHeights.enumerated()), id: \.offset) { index, height in
                let lineNumber = index + 1
                let isSelected = selectedLines.contains(lineNumber)
                
                Text(String(lineNumber))
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary.opacity(isSelected ? 1.0 : 0.5))
                    .frame(height: height, alignment: .top)
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .padding(.vertical, 12)
        .frame(minWidth: 40)
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.2))
        )
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1),
            alignment: .trailing
        )
        .onAppear {
            print("[EditableCodeBlockView] Line numbers view appeared with count: \(actualLineCount)")
        }
    }
}
