//
//  Lexer.swift
//  Swiftache
//
//  Created by Bjørn Olav Ruud on 01.09.14.
//  Copyright (c) 2014 Bjørn Olav Ruud. All rights reserved.
//

import Foundation

public enum TokenType: String {
    case Unknown = "Unknown"
    case Comment = "Comment"
    case CommentText = "CommentText"
    case EOF = "EOF"
    case Identifier = "Identifier"
    case Partial = "Partial"
    case PartialName = "PartialName"
    case SectionBegin = "SectionBegin"
    case SectionBeginInverted = "SectionBeginInverted"
    case SectionEnd = "SectionEnd"
    case StaticText = "Text"
    case TagBegin = "TagBegin"
    case TagEnd = "TagEnd"
    case TripleBegin = "TripleBegin"
    case TripleEnd = "TripleEnd"
    case Unescape = "Unescape"
}

public class Token: Equatable {
    private(set) var type: TokenType
    private(set) var textRange: NSRange

    init(type: TokenType, textRange: NSRange) {
        self.type = type
        self.textRange = textRange
    }
}

extension Token: DebugPrintable {
    public var debugDescription: String {
        return "{\(textRange.location), \(textRange.length)} \(type.toRaw())"
    }
}

public func ==(lhs: Token, rhs: Token) -> Bool {
    return lhs.type == rhs.type &&
           lhs.textRange.location == rhs.textRange.location &&
           lhs.textRange.length == rhs.textRange.length
}

public class Lexer {
    let scanner: Scanner

    private var searchRange = NSRange(location: 0, length: 0)
    private var tagRange = NSRange(location: 0, length: 0)
    private var tokenQueue = [Token]()

    private let tagRegex = NSRegularExpression(pattern: "\\{\\{\\{.*?\\}\\}\\}|\\{\\{.*?\\}\\}", options: .UseUnicodeWordBoundaries, error: nil)
    private let identifierRegex = NSRegularExpression(pattern: "^\\s*(.*?)\\s*$", options: .UseUnicodeWordBoundaries, error: nil)
    private let newlineRegex = NSRegularExpression(pattern: "\\r\\n|\\n|\\r|\\u2028|\\u2029", options: .UseUnicodeWordBoundaries, error: nil)

    init(scanner: Scanner) {
        self.scanner = scanner
    }

    func getToken() -> Token {
        // Return any queued tokens before searching for more
        if !tokenQueue.isEmpty {
            return tokenQueue.removeAtIndex(0)
        }

        let text = scanner.text
        let textLength = text.length
        searchRange.location = tagRange.location + tagRange.length
        searchRange.length = textLength - searchRange.location

        // Check for EOF
        if searchRange.location >= textLength {
            tagRange = NSRange(location: textLength, length: 0)
            return Token(type: .EOF, textRange: tagRange)
        }

        // Look for tag
        tagRange = tagRegex.rangeOfFirstMatchInString(text, options: NSMatchingOptions(0), range: searchRange)
        if tagRange.location == NSNotFound {
            // No tag found, the rest is static text
            tagRange = searchRange
            return Token(type: .StaticText, textRange: tagRange)
        }

        if tagRange.location > searchRange.location {
            // Tag found, but handle static text search has skipped over first
            tagRange = NSRange(location: searchRange.location, length: tagRange.location - searchRange.location)
            return Token(type: .StaticText, textRange: tagRange)
        }

        var beginToken: Token!
        var endToken: Token!
        var typeToken: Token?
        var contentToken: Token?
        var delimiterLength = 2

        // Look for triple mustache
        var contentRange = NSRange(location: tagRange.location + delimiterLength, length: tagRange.length - delimiterLength * 2)
        var tripleCharRange = NSRange(location: tagRange.location + delimiterLength, length: 1)
        let tripleChar = text.substringWithRange(tripleCharRange)
        if tripleChar != "{" {
            beginToken = Token(type: .TagBegin, textRange: NSRange(location: tagRange.location, length: delimiterLength))
            endToken = Token(type: .TagEnd, textRange: NSRange(location: tagRange.location + tagRange.length - delimiterLength, length: delimiterLength))
        } else {
            delimiterLength = 3
            beginToken = Token(type: .TripleBegin, textRange: NSRange(location: tagRange.location, length: delimiterLength))
            endToken = Token(type: .TripleEnd, textRange: NSRange(location: tagRange.location + tagRange.length - delimiterLength, length: delimiterLength))
            contentRange.location += 1
            contentRange.length -= 2
        }

        // Determine tag type, unless this is a triple stache tag
        var contentType: TokenType = .Identifier
        if beginToken.type == .TagBegin {
            let typeRange = NSRange(location: contentRange.location, length: 1)
            let typeMarker = text.substringWithRange(typeRange)
            switch typeMarker {
            case "#":
                typeToken = Token(type: .SectionBegin, textRange: typeRange)
            case "^":
                typeToken = Token(type: .SectionBeginInverted, textRange: typeRange)
            case "/":
                typeToken = Token(type: .SectionEnd, textRange: typeRange)
            case "&":
                typeToken = Token(type: .Unescape, textRange: typeRange)
            case "!":
                typeToken = Token(type: .Comment, textRange: typeRange)
                contentType = .CommentText
            case ">":
                typeToken = Token(type: .Partial, textRange: typeRange)
                contentType = .PartialName
            default:
                break
            }
            if typeToken != nil {
                contentRange.location++
                contentRange.length--
            }
        }

        // Extract tag content
        let result = identifierRegex.firstMatchInString(text, options: NSMatchingOptions(0), range: contentRange)
        if result?.numberOfRanges > 1 {
            let matchedGroupRange = result!.rangeAtIndex(1)
            contentToken = Token(type: contentType, textRange: matchedGroupRange)
        }

        // Return begin token and enqueue the rest
        if typeToken != nil {
            tokenQueue.append(typeToken!)
        }
        if contentToken != nil {
            tokenQueue.append(contentToken!)
        }
        tokenQueue.append(endToken)

        return beginToken
    }

    func textLocationForRange(range: NSRange) -> TextLocation {
        var loc = TextLocation()
        loc.position = range.location
        // Count newlines up to range location
        var searchRange = NSRange(location: 0, length: range.location)
        let matches = newlineRegex.matchesInString(scanner.text, options: NSMatchingOptions(0), range: searchRange) as [NSTextCheckingResult]
        if matches.isEmpty {
            loc.column = range.location
        } else {
            loc.line = matches.count
            let match = matches.last!
            loc.column = range.location - match.range.location - match.range.length
        }

        return loc
    }

    func allTokens() -> [Token] {
        var allTokens = [Token]()
        var token: Token!
        do {
            token = getToken()
            allTokens.append(token)
        } while token.type != .EOF

        return allTokens
    }
}
