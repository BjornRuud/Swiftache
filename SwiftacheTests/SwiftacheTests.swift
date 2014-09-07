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

    func testStringTarget() {
        let stache = Swiftache()
        let rendered = stache.render("A{{#a}}{{b}}{{/a}}C", context: ["a": true, "b": "B"])
        XCTAssertTrue(rendered, "Render failed.")
        XCTAssertEqual(stache.target!.text, "ABC", "Wrong parse output.")
    }

    func testFileTarget() {
        let url = cachesURL().URLByAppendingPathComponent("file test.html")
        let stache = Swiftache()
        let rendered = stache.render("A{{#a}}{{b}}{{/a}}C", context: ["a": true, "b": "B"], target: FileRenderTarget(fileURL: url))
        XCTAssertTrue(rendered, "Render failed.")
        XCTAssertEqual(stache.target!.text, "ABC", "Wrong parse output.")
    }
}
