//
//  Lexer.swift
//  Swiftache
//
//  Created by Bjørn Olav Ruud on 01.09.14.
//  Copyright (c) 2014 Bjørn Olav Ruud. All rights reserved.
//

import Foundation

enum TokenType {
    case Comment
    case Partial
    case SectionBegin
    case SectionEnd
    case SectionInvertedBegin
    case StaticText
    case TagBegin
    case TagEnd
    case TagBeginUnescaped
    case TagEndUnescaped
    case UnescapedVar
    case Variable
}

struct Token {
    let type: TokenType
    var textRange = NSRange(location: 0, length: 0)

    init(type: TokenType) {
        self.type = type
    }
}

class Lexer {
    let scanner: Scanner

    init(scanner: Scanner) {
        self.scanner = scanner
    }

    func tokenize() -> [Token] {
        var tokens: [Token] = []
        var lastChar = ""
        var token: Token?

        return []
    }
}
