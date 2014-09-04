//
//  SwiftacheTests.swift
//  SwiftacheTests
//
//  Created by Bjørn Olav Ruud on 01.09.14.
//  Copyright (c) 2014 Bjørn Olav Ruud. All rights reserved.
//

import UIKit
import XCTest

class SwiftacheTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testLexer() {
        let singleExample = "Behold, Mustache!\n{{awesome}}"
        let sectionExample = "Test\u{2028} {{#section}}Yo! {{! FIXME \u{1F60E}}}{{& yo}}{{/section}}\n{{{triple_madness}}}\r\nThe End"

        let template = Template(text: sectionExample)
        let lexer = Lexer(template: template)
        let tokens = lexer.allTokens()
        let location = lexer.textLocationForRange(tokens[tokens.endIndex - 1].textRange)
        println("pos: \(location.position), line: \(location.line), col: \(location.column)")
    }

}