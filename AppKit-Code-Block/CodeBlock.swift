//
//  CodeBlock.swift
//  Notes-app
//
//  Created by Frederik Handberg on 12/10/2025.
//

import Foundation

struct CodeBlock: Codable, Identifiable {
    let id: String
    var language: String
    var content: String
    var indent: Int

    init(
        id: String = UUID().uuidString,
        language: String = "",
        content: String = "",
        indent: Int = 0
    ) {
        self.id = id
        self.language = language
        self.content = content
        self.indent = indent
    }
}
