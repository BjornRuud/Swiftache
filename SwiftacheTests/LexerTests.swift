//
//  LexerTests.swift
//  Swiftache
//
//  Created by Bjørn Olav Ruud on 03.09.14.
//  Copyright (c) 2014 Bjørn Olav Ruud. All rights reserved.
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

    func lexerWithFile(url: NSURL) -> Lexer {
        let template = Template(fileURL: url)
        return Lexer(template: template)
    }

    func lexerWithText(text: String) -> Lexer {
        let template = Template(text: text)
        return Lexer(template: template)
    }

    func testEmptyTag() {
        var lexer = lexerWithText("{{}}")
        var tokens = lexer.allTokens()
        XCTAssertEqual(tokens.count, 3, "Wrong token count for empty tag.")

        lexer = lexerWithText("{{ }}")
        tokens = lexer.allTokens()
        XCTAssertEqual(tokens.count, 3, "Wrong token count for empty tag with space.")

        lexer = lexerWithText("{{   }}")
        tokens = lexer.allTokens()
        XCTAssertEqual(tokens.count, 3, "Wrong token count for empty tag with 3 spaces.")
    }

    func testVariable() {
        var lexer = lexerWithText("{{a}}")
        var refTokens: [Token] = [
            Token(type: .TagBegin, textRange: NSRange(location: 0, length: 2)),
            Token(type: .Identifier, textRange: NSRange(location: 2, length: 1)),
            Token(type: .TagEnd, textRange: NSRange(location: 3, length: 2)),
            Token(type: .EOF, textRange: NSRange(location: 5, length: 0))
        ]
        var tokens = lexer.allTokens()
        XCTAssertEqual(refTokens, tokens, "Reference tokens not same as processed tokens for variable")

        lexer = lexerWithText("{{ a }}")
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
            let lexer = lexerWithText("{{\(symbol)a}}")
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

    func testComplexFile() {
        let fileURL = NSBundle.mainBundle().URLForResource("list", withExtension: "html")
        XCTAssertNotNil(fileURL, "Missing template.")
        let lexer = lexerWithFile(fileURL!)
        let tokens = lexer.allTokens()
        XCTAssertEqual(tokens.count, 58, "Wrong token count!")
    }

    func testComplexFilePerformance() {
        let fileURL = NSBundle.mainBundle().URLForResource("list", withExtension: "html")
        XCTAssertNotNil(fileURL, "Missing template.")
        measureBlock {
            let lexer = self.lexerWithFile(fileURL!)
            var token: Token!
            do {
                token = lexer.getToken()
            } while token.type != .EOF
        }
    }

}
