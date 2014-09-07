//
//  LexerTests.swift
//  Swiftache
//
//  Copyright (c) 2014 Bjørn Olav Ruud. All rights reserved.
//  Licensed under the MIT License (MIT). See LICENSE.txt for details.
//

import Foundation
import XCTest

class LexerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testEmptyTag() {
        var lexer = newLexer("{{}}")
        var tokens = lexer.allTokens()
        XCTAssertEqual(tokens.count, 3, "Wrong token count for empty tag.")

        lexer = newLexer("{{ }}")
        tokens = lexer.allTokens()
        XCTAssertEqual(tokens.count, 3, "Wrong token count for empty tag with space.")

        lexer = newLexer("{{   }}")
        tokens = lexer.allTokens()
        XCTAssertEqual(tokens.count, 3, "Wrong token count for empty tag with 3 spaces.")
    }

    func testVariable() {
        var lexer = newLexer("{{a}}")
        var refTokens: [Token] = [
            Token(type: .TagBegin, textRange: NSRange(location: 0, length: 2)),
            Token(type: .Identifier, textRange: NSRange(location: 2, length: 1)),
            Token(type: .TagEnd, textRange: NSRange(location: 3, length: 2)),
            Token(type: .EOF, textRange: NSRange(location: 5, length: 0))
        ]
        var tokens = lexer.allTokens()
        XCTAssertEqual(refTokens, tokens, "Reference tokens not same as processed tokens for variable")

        lexer = newLexer("{{ a }}")
        refTokens = [
            Token(type: .TagBegin, textRange: NSRange(location: 0, length: 2)),
            Token(type: .Identifier, textRange: NSRange(location: 3, length: 1)),
            Token(type: .TagEnd, textRange: NSRange(location: 5, length: 2)),
            Token(type: .EOF, textRange: NSRange(location: 7, length: 0))
        ]
        tokens = lexer.allTokens()
        XCTAssertEqual(refTokens, tokens, "Reference tokens not same as processed tokens for variable with spaces")
    }

    func testTagTypes() {
        let symbolTypeContent: [(String, TokenType, TokenType)] = [
            ("#", .SectionBegin, .Identifier),
            ("^", .SectionBeginInverted, .Identifier),
            ("/", .SectionEnd, .Identifier),
            ("&", .Unescape, .Identifier),
            ("!", .Comment, .CommentText),
            (">", .Partial, .PartialName)
        ]
        for (symbol, type, contentType) in symbolTypeContent {
            let lexer = newLexer("{{\(symbol)a}}")
            let refTokens: [Token] = [
                Token(type: .TagBegin, textRange: NSRange(location: 0, length: 2)),
                Token(type: type, textRange: NSRange(location: 2, length: 1)),
                Token(type: contentType, textRange: NSRange(location: 3, length: 1)),
                Token(type: .TagEnd, textRange: NSRange(location: 4, length: 2)),
                Token(type: .EOF, textRange: NSRange(location: 6, length: 0))
            ]
            let tokens = lexer.allTokens()
            XCTAssertEqual(refTokens, tokens, "Reference tokens not same as processed tokens for tag type \(symbol) (\(type.toRaw()))")
        }
    }

    func testSection() {
        var lexer = newLexer("{{#a}}{{/a}}")
        var refTokens: [Token] = [
            Token(type: .TagBegin, textRange: NSRange(location: 0, length: 2)),
            Token(type: .SectionBegin, textRange: NSRange(location: 2, length: 1)),
            Token(type: .Identifier, textRange: NSRange(location: 3, length: 1)),
            Token(type: .TagEnd, textRange: NSRange(location: 4, length: 2)),

            Token(type: .TagBegin, textRange: NSRange(location: 6, length: 2)),
            Token(type: .SectionEnd, textRange: NSRange(location: 8, length: 1)),
            Token(type: .Identifier, textRange: NSRange(location: 9, length: 1)),
            Token(type: .TagEnd, textRange: NSRange(location: 10, length: 2)),
            Token(type: .EOF, textRange: NSRange(location: 12, length: 0))
        ]
        var tokens = lexer.allTokens()
        XCTAssertEqual(refTokens, tokens)
    }

    func testComplexFile() {
        let fileURL = NSBundle.mainBundle().URLForResource("list", withExtension: "html")
        XCTAssertNotNil(fileURL, "Missing template.")
        let lexer = newLexer(fileURL!)
        let tokens = lexer.allTokens()
        XCTAssertEqual(tokens.count, 58, "Wrong token count!")
    }

}
