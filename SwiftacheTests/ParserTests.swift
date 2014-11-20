//
//  ParserTests.swift
//  Swiftache
//
//  Copyright (c) 2014 Bjørn Olav Ruud. All rights reserved.
//  Licensed under the MIT License (MIT). See LICENSE.txt for details.
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

    func testComment() {
        let parser = newParser("A {{! comment here }}B")
        let context: RenderContext = [:]
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, "A B")
    }

    func testTextEscape() {
        var parser = newParser("{{a}}")
        let escapeChars = "&\"'<>"
        let context: RenderContext = ["a": escapeChars]
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, escapeChars.stringByEscapingXMLEntities)

        parser = newParser("{{{a}}}")
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, escapeChars)

        parser = newParser("{{&a}}")
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, escapeChars)
    }
    func testIdentifier() {
        let parser = newParser("{{a}}")
        let context: RenderContext = ["a": "A"]
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, "A")
    }

    func testLambda() {
        var parser = newParser("{{#a}}{{b}}{{/a}}")
        var lambda: Lambda = { (text, render) -> String in
            return render(text).uppercaseString
        }
        var context: RenderContext = ["a": lambda, "b": "abc"]
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, "ABC")

        parser = newParser("{{#a}}{{b}}{{/a}}")
        lambda = { (text, render) -> String in
            return "<i>" + render(text).lowercaseString + "</i>"
        }
        context = ["a": lambda, "b": "ABC"]
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, "<i>abc</i>")
    }

    func testPartial() {
        let parser = newParser("A{{> simple partial.html }}")
        let context: RenderContext = ["b": "B"]
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, "AB")
    }

    func testSection() {
        let parser = newParser("{{#a}}{{b}}{{/a}}")
        let b: RenderContext = ["b": "B\n"]
        let context: RenderContext = ["a": [b, b]]
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, "B\nB\n")
    }

    func testSectionBool() {
        var parser = newParser("{{#a}}A{{/a}}")
        var context: RenderContext = ["a": false]
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, "")

        context["a"] = true
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, "A")

        parser = newParser("{{^a}}A{{/a}}")
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, "")

        context["a"] = false
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, "A")
}

    func testSectionContext() {
        var parser = newParser("{{^a}}{{b}}{{/a}}")
        var b: RenderContext = ["b": "B"]
        var a: RenderContext = ["a": b]
        parser.parseWithContext(a)
        XCTAssertEqual(parser.renderTarget!.text, "")

        parser = newParser("{{#a}}{{b}}{{/a}}")
        parser.parseWithContext(a)
        XCTAssertEqual(parser.renderTarget!.text, "B")
    }

    func testNestedSection() {
        var parser = newParser("{{#a}}{{#b}}{{c}}{{/b}}{{/a}}")
        var c: RenderContext = ["c": "C"]
        var a: RenderContext = ["a": true, "b": c]
        parser.parseWithContext(a)
        XCTAssertEqual(parser.renderTarget!.text, "C")

        parser = newParser("{{^a}}{{#b}}{{c}}{{/b}}{{/a}}")
        parser.parseWithContext(a)
        XCTAssertEqual(parser.renderTarget!.text, "")
    }

    func testStaticText() {
        let parser = newParser("A")
        let context: RenderContext = [:]
        parser.parseWithContext(context)
        XCTAssertEqual(parser.renderTarget!.text, "A")
    }
}
