//
//  RenderTargetTests.swift
//  Swiftache
//
//  Created by Bjørn Olav Ruud on 07.09.14.
//  Copyright (c) 2014 Bjørn Olav Ruud. All rights reserved.
//

import UIKit
import XCTest

class RenderTargetTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testStringTarget() {
        var parser = newParser("A{{#a}}{{&b}}C{{/a}}")
        var b: RenderContext = ["b": "B"]
        var a: RenderContext = ["a": b]
        parser.parseWithContext(a)
        XCTAssertEqual(parser.renderTarget!.text, "ABC")
    }

    func testFileTarget() {
        let url = cachesURL().URLByAppendingPathComponent("file render.html")
        var parser = newParser("A{{#a}}{{&b}}C{{/a}}", target: FileRenderTarget(fileURL: url, encoding: NSUTF8StringEncoding))
        var b: RenderContext = ["b": "B"]
        var a: RenderContext = ["a": b]
        parser.parseWithContext(a)
        XCTAssertEqual(parser.renderTarget!.text, "ABC")
    }

}
