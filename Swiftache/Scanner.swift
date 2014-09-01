//
//  Scanner.swift
//  Swiftache
//
//  Created by Bjørn Olav Ruud on 01.09.14.
//  Copyright (c) 2014 Bjørn Olav Ruud. All rights reserved.
//

import Foundation

struct TextLocation {
    var position = 0
    var line = 0
    var column = 0
}

struct CharacterEnumerationResult {
    var characters = 0
    var lines = 0
}

public class Scanner {
    private(set) var fileURL: NSURL
    private(set) var fileEncoding: NSStringEncoding

    private let text: NSString
    private let data: NSData

    init(fileURL: NSURL, encoding: NSStringEncoding) {
        self.fileURL = fileURL
        fileEncoding = encoding

        var dataError = NSErrorPointer()
        let possibleData: NSData? = NSData(contentsOfURL: fileURL, options: NSDataReadingOptions.DataReadingMappedAlways, error: dataError)
        data = possibleData ?? NSData()

        let possibleText: NSString? = NSString(bytesNoCopy: UnsafeMutablePointer<Void>(data.bytes), length: data.length, encoding: encoding, freeWhenDone: false)
        text = possibleText ?? NSString()
    }

    convenience init(fileURL: NSURL) {
        self.init(fileURL: fileURL, encoding: NSUTF8StringEncoding)
    }

    init(text: String) {
        fileURL = NSURL()
        fileEncoding = NSUTF8StringEncoding
        self.text = text
        data = NSData()
    }

    func enumerateCharacters(charHandler: (character: String, location: TextLocation, range: NSRange, inout stop: Bool) -> Void) -> CharacterEnumerationResult {
        var locSummary = TextLocation()
        var result = CharacterEnumerationResult()
        let newlineSet = NSCharacterSet.newlineCharacterSet()
        text.enumerateSubstringsInRange(NSRange(location: 0, length: text.length), options: .ByComposedCharacterSequences) {
            (subString, subStringRange, enclosingRange, stop) -> Void in

            var stopEnumeration = false
            charHandler(character: subString, location: locSummary, range: subStringRange, stop: &stopEnumeration)

            // Update location for next character
            locSummary.position++
            // Check for newlines (U+000A–U+000D, U+0085)
            let newlineRange = subString.rangeOfCharacterFromSet(newlineSet)
            if newlineRange != nil {
                locSummary.line++
                locSummary.column = 0
            } else {
                locSummary.column++
            }

            if stopEnumeration {
                stop.memory = ObjCBool(true)
            }
        }
        result.characters = locSummary.position
        result.lines = locSummary.line + 1

        return result
    }
}
