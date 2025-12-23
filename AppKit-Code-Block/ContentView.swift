//
//  ContentView.swift
//  AppKit-Code-Block
//
//  Created by Frederik Handberg on 23/12/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var codeBlock = CodeBlock(
        language: "swift",
        content: """
        func fibonacci(_ n: Int) -> Int {
            guard n > 1 else { return n }
            return fibonacci(n - 1) + fibonacci(n - 2)
        }
        
        print(fibonacci(10))
        """
    )
    
    @State private var isFocused = false
    
    var body: some View {
        VStack {
            Text("Code Block Demo")
                .font(.title)
                .padding()
            
            EditableCodeBlockView(
                block: codeBlock,
                isFocused: isFocused,
                onSelect: {
                    print("Selected")
                },
                onFocus: {
                    isFocused = true
                    print("Focused")
                },
                onUnfocus: {
                    isFocused = false
                    print("Unfocused")
                },
                onChange: { updatedBlock in
                    codeBlock = updatedBlock
                    print("Content changed")
                }
            )
            .frame(maxWidth: 600)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
