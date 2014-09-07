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
        let context: TemplateContext = [:]
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, "A B")
    }

    func testTextEscape() {
        var parser = parserForText("{{a}}")
        let escapeChars = "&\"'<>"
        let context: TemplateContext = ["a": escapeChars]
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
        let context: TemplateContext = ["a": "A"]
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, "A")
    }

    func testPartial() {
        let parser = parserForText("A{{> simple partial.html }}")
        let context: TemplateContext = ["b": "B"]
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, "AB")
    }

    func testSection() {
        let parser = parserForText("{{#a}}{{b}}{{/a}}")
        let b: TemplateContext = ["b": "B\n"]
        let context: TemplateContext = ["a": [b, b]]
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, "B\nB\n")
    }

    func testSectionBool() {
        var parser = parserForText("{{#a}}A{{/a}}")
        var context: TemplateContext = ["a": false]
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, "")

        context["a"] = true
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, "A")

        parser = parserForText("{{^a}}A{{/a}}")
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, "")

        context["a"] = false
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, "A")
}

    func testSectionContext() {
        var parser = parserForText("{{^a}}{{b}}{{/a}}")
        var b: TemplateContext = ["b": "B"]
        var a: TemplateContext = ["a": b]
        parser.parseWithContext(a)
        XCTAssertEqual(parser.renderTarget!.text, "")

        parser = parserForText("{{#a}}{{b}}{{/a}}")
        parser.parseWithContext(a)
        XCTAssertEqual(parser.renderTarget!.text, "B")
    }

    func testNestedSection() {
        var parser = parserForText("{{#a}}{{#b}}{{c}}{{/b}}{{/a}}")
        var c: TemplateContext = ["c": "C"]
        var a: TemplateContext = ["a": true, "b": c]
        parser.parseWithContext(a)
        XCTAssertEqual(parser.renderTarget!.text, "C")

        parser = parserForText("{{^a}}{{#b}}{{c}}{{/b}}{{/a}}")
        parser.parseWithContext(a)
        XCTAssertEqual(parser.renderTarget!.text, "")
    }

    func testStaticText() {
        let parser = parserForText("A")
        let context: TemplateContext = [:]
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, "A")
    }
}
