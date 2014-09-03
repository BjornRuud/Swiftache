//
//  Scanner.swift
//  Swiftache
//
//  Created by Bjørn Olav Ruud on 01.09.14.
//  Copyright (c) 2014 Bjørn Olav Ruud. All rights reserved.
//

import Foundation

typealias CharacterEnumerationHandler = (character: String, location: TextLocation, range: NSRange, inout stop: Bool) -> Void

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

    let text: NSString
    let data: NSData

    private(set) var currentCharRange: NSRange = NSRange(location: 0, length: 0)
    private(set) var currentCharLocation = TextLocation()
    private(set) var searchRange: NSRange
    private(set) var nextCharLocation = TextLocation()

    private let newlineSet = NSCharacterSet.newlineCharacterSet()
    private let whitespaceSet = NSCharacterSet.whitespaceCharacterSet()

    init(fileURL: NSURL, encoding: NSStringEncoding) {
        self.fileURL = fileURL
        fileEncoding = encoding

        var dataError = NSErrorPointer()
        let possibleData: NSData? = NSData(contentsOfURL: fileURL, options: NSDataReadingOptions.DataReadingMappedAlways, error: dataError)
        data = possibleData ?? NSData()

        let possibleText: NSString? = NSString(bytesNoCopy: UnsafeMutablePointer<Void>(data.bytes), length: data.length, encoding: encoding, freeWhenDone: false)
        text = possibleText ?? NSString()

        searchRange = NSRange(location: 0, length: text.length)
    }

    convenience init(fileURL: NSURL) {
        self.init(fileURL: fileURL, encoding: NSUTF8StringEncoding)
    }

    init(text: NSString) {
        fileURL = NSURL()
        fileEncoding = NSUTF8StringEncoding
        self.text = text
        data = NSData()
        searchRange = NSRange(location: 0, length: self.text.length)
    }

    func characterIsNewline(char: String) -> Bool {
        let newlineRange = char.rangeOfCharacterFromSet(newlineSet)
        return newlineRange != nil
    }

    func characterIsWhitespace(char: String) -> Bool {
        let whitespaceRange = char.rangeOfCharacterFromSet(whitespaceSet)
        return whitespaceRange != nil
    }

    func enumerateCharacters(charHandler: CharacterEnumerationHandler) -> CharacterEnumerationResult {
        return enumerateCharactersInRange(NSRange(location: 0, length: text.length), charHandler: charHandler)
    }

    func enumerateCharactersInRange(range: NSRange, charHandler: CharacterEnumerationHandler) -> CharacterEnumerationResult {
        var locSummary = TextLocation()
        var result = CharacterEnumerationResult()
        text.enumerateSubstringsInRange(range, options: .ByComposedCharacterSequences) {
            (subString, subStringRange, enclosingRange, stop) -> Void in

            var stopEnumeration = false
            charHandler(character: subString, location: locSummary, range: subStringRange, stop: &stopEnumeration)

            // Update location for next character
            locSummary.position++
            // Check for newlines (U+000A–U+000D, U+0085)
            if self.characterIsNewline(subString) {
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

    func getCharacter() -> String {
        if searchRange.location >= text.length {
            // EOF
            return ""
        }

        var char: String?
        currentCharLocation = nextCharLocation
        text.enumerateSubstringsInRange(searchRange, options: .ByComposedCharacterSequences) {
            (subString, subStringRange, enclosingRange, stop) -> Void in

            char = subString
            self.currentCharRange = subStringRange
            self.searchRange.location += subStringRange.length
            stop.memory = ObjCBool(true)
        }
        // Update location for next character
        nextCharLocation.position++
        // Check for newlines (U+000A–U+000D, U+0085)
        if char != nil && characterIsNewline(char!) {
            nextCharLocation.line++
            nextCharLocation.column = 0
        } else {
            nextCharLocation.column++
        }

        return char ?? ""
    }
}
