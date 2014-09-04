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

struct TextLocation {
    var position = 0
    var line = 0
    var column = 0
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
    let template: Template

    private var searchRange = NSRange(location: 0, length: 0)
    private var tagRange = NSRange(location: 0, length: 0)
    private var tokenQueue = [Token]()

    private let tagBeginRegex = NSRegularExpression(pattern: "\\{\\{\\{?", options: .UseUnicodeWordBoundaries, error: nil)
    private let tagEndRegex = NSRegularExpression(pattern: "\\}?\\}\\}", options: .UseUnicodeWordBoundaries, error: nil)
    private let identifierRegex = NSRegularExpression(pattern: "^\\s*(.*?)\\s*$", options: .UseUnicodeWordBoundaries | .DotMatchesLineSeparators, error: nil)
    private let newlineRegex = NSRegularExpression(pattern: "\\r\\n|\\n|\\r|\\u2028|\\u2029", options: .UseUnicodeWordBoundaries, error: nil)

    init(template: Template) {
        self.template = template
    }

    func reset() {
        searchRange = NSRange(location: 0, length: 0)
        tagRange = NSRange(location: 0, length: 0)
        tokenQueue = [Token]()
    }

    func getToken() -> Token {
        // Return any queued tokens before searching for more
        if !tokenQueue.isEmpty {
            return tokenQueue.removeAtIndex(0)
        }

        let text = template.text
        let textLength = text.length
        searchRange.location = tagRange.location + tagRange.length
        searchRange.length = textLength - searchRange.location

        // Check for EOF
        if searchRange.location >= textLength {
            tagRange.location = textLength
            tagRange.length = 0
            return Token(type: .EOF, textRange: tagRange)
        }

        // Look for beginning of tag
        let tagBeginRange = tagBeginRegex.rangeOfFirstMatchInString(text, options: NSMatchingOptions(0), range: searchRange)
        if tagBeginRange.location == NSNotFound {
            // No tag found, the rest is static text
            tagRange = searchRange
            return Token(type: .StaticText, textRange: tagRange)
        }

        if tagBeginRange.location > searchRange.location {
            // Beginning of tag was found, but handle skipped static text first
            tagRange.location = searchRange.location
            tagRange.length = tagBeginRange.location - searchRange.location
            tokenQueue.append(Token(type: .StaticText, textRange: tagRange))
        }

        // Determine if triple tag and enqueue appropriate token
        let beginTagType: TokenType = tagBeginRange.length == 3 ? .TripleBegin : .TagBegin
        let beginToken = Token(type: beginTagType, textRange: tagBeginRange)
        tokenQueue.append(beginToken)

        // Look for end of tag
        var endToken: Token!
        searchRange.location = tagBeginRange.location + tagBeginRange.length
        searchRange.length = textLength - searchRange.location
        let tagEndRange = tagEndRegex.rangeOfFirstMatchInString(text, options: NSMatchingOptions(0), range: searchRange)
        if tagEndRange.location == NSNotFound {
            // No end tag found, treat everything after beginning of tag as static text
            tagRange = searchRange
            tokenQueue.append(Token(type: .StaticText, textRange: tagRange))
            return tokenQueue.removeAtIndex(0)
        } else {
            // Create end token but do not enqueue it until tag type and content
            // tokens have been resolved
            let endTagType: TokenType = tagEndRange.length == 3 ? .TripleEnd : .TagEnd
            endToken = Token(type: endTagType, textRange: tagEndRange)
        }

        // Set found tag range
        tagRange.location = tagBeginRange.location
        tagRange.length = tagEndRange.location + tagEndRange.length - tagBeginRange.location
        // Set range of tag content
        var contentRange = NSRange(location: tagBeginRange.location + tagBeginRange.length,
                                   length: tagEndRange.location - (tagBeginRange.location + tagBeginRange.length))

        // Determine tag type, unless this is a triple stache tag
        var typeToken: Token?
        var contentType: TokenType = .Identifier
        if beginToken.type == .TagBegin {
            let typeRange = NSRange(location: contentRange.location, length: 1)
            let typeMarker = text.substringWithRange(typeRange)
            var tagType: TokenType = .Unknown
            switch typeMarker {
            case "#":
                tagType = .SectionBegin
            case "^":
                tagType = .SectionBeginInverted
            case "/":
                tagType = .SectionEnd
            case "&":
                tagType = .Unescape
            case "!":
                tagType = .Comment
                contentType = .CommentText
            case ">":
                tagType = .Partial
                contentType = .PartialName
            default:
                break
            }
            if tagType != .Unknown {
                typeToken = Token(type: tagType, textRange: typeRange)
                contentRange.location++
                contentRange.length--
            }
        }

        // Find range of tag content if tag isn't empty
        var contentToken: Token?
        if contentRange.location != tagEndRange.location {
            let result = identifierRegex.firstMatchInString(text, options: NSMatchingOptions(0), range: contentRange)
            if result?.numberOfRanges > 1 {
                let matchedGroupRange = result!.rangeAtIndex(1)
                if matchedGroupRange.location != NSNotFound && matchedGroupRange.length != 0 {
                    contentToken = Token(type: contentType, textRange: matchedGroupRange)
                }
            }
        }

        // Enqueue tokens and return first in queue
        if typeToken != nil {
            tokenQueue.append(typeToken!)
        }
        if contentToken != nil {
            tokenQueue.append(contentToken!)
        }
        tokenQueue.append(endToken)

        return tokenQueue.removeAtIndex(0)
    }

    func textLocationForRange(range: NSRange) -> TextLocation {
        var loc = TextLocation()
        loc.position = range.location
        // Count newlines up to range location
        let searchRange = NSRange(location: 0, length: range.location)
        let matches = newlineRegex.matchesInString(template.text, options: NSMatchingOptions(0), range: searchRange) as [NSTextCheckingResult]
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

extension Lexer {
    func debugDescriptionForToken(token: Token) -> String {
        let subString = template.text.substringWithRange(token.textRange)
        var desc = token.debugDescription + " = \(subString)"
        return desc
    }
}