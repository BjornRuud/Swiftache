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

    func testVariable() {
        let template = Template(text: "{{mustache}}")
        let refTokens: [Token] = [
            Token(type: .TagBegin, textRange: NSRange(location: 0, length: 2)),
            Token(type: .Identifier, textRange: NSRange(location: 2, length: 8)),
            Token(type: .TagEnd, textRange: NSRange(location: 10, length: 2)),
            Token(type: .EOF, textRange: NSRange(location: 12, length: 0))
        ]

        let lexer = Lexer(template: template)
        let tokens = lexer.allTokens()
        XCTAssertEqual(refTokens, tokens, "Reference tokens not same as processed tokens")
    }

    func testComplexFile() {
        let fileURL = NSBundle.mainBundle().URLForResource("list", withExtension: "html")
        XCTAssertNotNil(fileURL, "Missing template.")
        let template = Template(fileURL: fileURL!)
        let lexer = Lexer(template: template)
        let tokens = lexer.allTokens()
        XCTAssertEqual(tokens.count, 58, "Wrong token count!")
    }

    func testSmallTemplatePerformance() {
        measureBlock {
            let fileURL = NSBundle.mainBundle().URLForResource("list", withExtension: "html")
            XCTAssertNotNil(fileURL, "Missing template.")
            let template = Template(fileURL: fileURL!)
            let lexer = Lexer(template: template)
            var token: Token!
            do {
                token = lexer.getToken()
            } while token.type != .EOF
        }
    }

}
