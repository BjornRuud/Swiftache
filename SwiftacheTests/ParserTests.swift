//
//  ParserTests.swift
//  Swiftache
//
//  Created by Bjørn Olav Ruud on 06.09.14.
//  Copyright (c) 2014 Bjørn Olav Ruud. All rights reserved.
//

import UIKit
import XCTest

class ParserTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func parserForText(text: String) -> Parser {
        let template = Template(text: text)
        let lexer = Lexer(template: template)
        let target = StringRenderTarget()
        return Parser(lexer: lexer, target: target)
    }

    func testComment() {
        let parser = parserForText("A {{! comment here }}B")
        let context: Context = [:]
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, "A B")
    }

    func testTextEscape() {
        var parser = parserForText("{{a}}")
        let escapeChars = "&\"'<>"
        let context: Context = ["a": escapeChars]
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, escapeChars.stringByEscapingXMLEntities)

        parser = parserForText("{{{a}}}")
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, escapeChars)

        parser = parserForText("{{&a}}")
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, escapeChars)
    }
    func testIdentifier() {
        let parser = parserForText("{{a}}")
        let context: Context = ["a": "A"]
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, "A")
    }

    func testPartial() {
        let parser = parserForText("A{{> simple partial.html }}")
        let context: Context = ["b": "B"]
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, "AB")
    }

    func testSection() {
        let parser = parserForText("{{#a}}{{b}}{{/a}}")
        let b: Context = ["b": "B\n"]
        let context: Context = ["a": [b, b]]
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, "B\nB\n")
    }

    func testSectionBool() {
        let parser = parserForText("{{#a}}A{{/a}}")
        var context: Context = ["a": false]
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, "")

        context["a"] = true
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, "A")
    }

    func testStaticText() {
        let parser = parserForText("A")
        let context: Context = [:]
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, "A")
    }
}
