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

    func testScanner() {
        //let scanner = Scanner(fileURL: NSURL(string: "http://localhost"), encoding: NSUTF8StringEncoding)
        let scanner = Scanner(text: "Behold, Mustache!\n{{awesome}}")
        let result = scanner.enumerateCharacters { (character, location, range, stop) -> Void in
            println("\(character) (pos: \(location.position), line: \(location.line), col: \(location.column))")
        }
        println("\(result.characters) characters, \(result.lines) lines")
    }

}
