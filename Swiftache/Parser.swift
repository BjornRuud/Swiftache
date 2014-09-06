//
//  Parser.swift
//  Swiftache
//
//  Created by Bjørn Olav Ruud on 03.09.14.
//  Copyright (c) 2014 Bjørn Olav Ruud. All rights reserved.
//

import Foundation

private let ParserErrorDomain = "net.bjornruud.Swiftache.Parser"
private let RootSectionName = "___root___"

public typealias Context = [String: Any]

class Section {
    var name: String
    var contexts = [Context]()
    var activeContextIndex = 0
    var position = 0
    var shouldRender = true

    init(name: String) {
        self.name = name
    }
}

public class Parser {
    public let lexer: Lexer
    public var renderTarget: RenderTarget?

    private var sectionStack = [Section]()
    private var stopParsing = false
    private var currentToken: Token!

    init(lexer: Lexer) {
        self.lexer = lexer
    }

    convenience init(lexer: Lexer, target: RenderTarget) {
        self.init(lexer: lexer)
        renderTarget = target
    }

    // MARK: - Parsing

    public func parseWithContext(context: Context) {
        // Add root section
        let section = Section(name: RootSectionName)
        section.contexts.append(context)
        sectionStack.push(section)
        while !stopParsing {
            parseStart()
        }
        sectionStack.pop()
        lexer.reset()
        stopParsing = false
    }

    func parseStart() {
        // Valid tokens to start with are static text and opening tags
        currentToken = lexer.getToken()
        switch currentToken.type {
        case .EOF:
            stopParsing = true
            // EOF is an error if there are unprocessed sections
            if sectionStack.count > 1 {
                // Report error
            }
        case .StaticText:
            // Render text
            renderToken(currentToken, escaped: false)
        case .TagBegin:
            parseTag(currentToken)
        case .TripleBegin:
            parseTriple(currentToken)
        default:
            // Invalid token
            let loc = lexer.textLocationForRange(currentToken.textRange)
            stopParsing = true
        }
    }

    func parseTag(beginToken: Token) {
        var escape = true
        currentToken = lexer.getToken()

        switch currentToken.type {

        case .SectionBegin:
            fallthrough
        case .SectionBeginInverted:
            parseSection(beginToken, typeToken: currentToken)
            return
        case .SectionEnd:
            parseSectionEnd(beginToken)
            return

        case .Unescape:
            escape = false
            currentToken = lexer.getToken()
        case .Comment:
            parseComment(beginToken)
            return
        case .Partial:
            parsePartial(beginToken)
            return
        default:
            break
        }

        // If we get here this is a normal tag with an identifier
        if currentToken.type != .Identifier {
            // Not expected token, report error
            stopParsing = true
            return
        }

        renderToken(currentToken, escaped: escape)

        // Verify end token
        currentToken = lexer.getToken()
        if currentToken.type != .TagEnd {
            stopParsing = true
            return
        }
    }

    func parseComment(beginToken: Token) {
        currentToken = lexer.getToken()
        // Expected tokens are optional comment text followed by closing tag
        switch currentToken.type {
        case .CommentText:
            // Comments are ignored
            break
        case .TagEnd:
            // Empty tag
            return
        default:
            // Invalid token, report error
            stopParsing = true
            return
        }

        currentToken = lexer.getToken()
        if currentToken.type != .TagEnd {
            stopParsing = true
            return
        }
    }

    func parsePartial(beginToken: Token) {
        currentToken = lexer.getToken()
        // Expected tokens are partial name followed by closing tag
        var name: String!
        var fileURL: NSURL?
        switch currentToken.type {
        case .PartialName:
            // Validate partial file name
            let name = lexer.template.text.substringWithRange(currentToken.textRange)
            fileURL = NSBundle.mainBundle().URLForResource(name, withExtension: nil)
            if fileURL == nil {
                // File not found
                // FIXME: Should this be an error?
            }
        default:
            // Invalid token, report error
            stopParsing = true
            return
        }

        currentToken = lexer.getToken()
        if currentToken.type != .TagEnd {
            stopParsing = true
            return
        }

        // Create parser for included template and parse it
        if fileURL != nil {
            let partialTemplate = Template(fileURL: fileURL!)
            let partialLexer = Lexer(template: partialTemplate)
            let partialParser = Parser(lexer: partialLexer)
            partialParser.renderTarget = renderTarget
            // Partials use the root context
            partialParser.parseWithContext(sectionStack[0].contexts[0])
            // TODO: Error checking
        }
    }

    func parseSection(beginToken: Token, typeToken: Token) {
        currentToken = lexer.getToken()
        var section: Section!
        // Expected tokens are section name followed by closing tag
        switch currentToken.type {
        case .Identifier:
            let sectionName = lexer.template.text.substringWithRange(currentToken.textRange)
            section = Section(name: sectionName)

            // Look for section in current context
            let sectionValue = valueForIdentifier(sectionName)
            // Sections are activated by a bool or by an array
            if sectionValue == nil {
                section.shouldRender = false
            }
            else if let boolValue = sectionValue as? Bool {
                section.shouldRender = boolValue
                if boolValue {
                    // Section with bool uses root context
                    section.contexts = sectionStack[0].contexts
                }
            }
            else if let arrayValue = sectionValue as? [Context] {
                section.contexts.extend(arrayValue)
                if section.contexts.count == 0 {
                    section.shouldRender = false
                }
            }
            else {
                // Section value is not supported
                section.shouldRender = false
            }
            sectionStack.push(section)
        default:
            // Invalid token, report error
            stopParsing = true
            return
        }

        currentToken = lexer.getToken()
        if currentToken.type != .TagEnd {
            sectionStack.pop()
            stopParsing = true
            return
        }
        section.position = currentToken.textRange.location + currentToken.textRange.length
    }

    func parseSectionEnd(beginToken: Token) {
        currentToken = lexer.getToken()
        switch currentToken.type {
        case .Identifier:
            let section = sectionStack.last!
            let sectionName = lexer.template.text.substringWithRange(currentToken.textRange)
            if sectionName != section.name {
                // End of wrong section
                stopParsing = true
                return
            }
            // See if we need another iteration
            if section.activeContextIndex < section.contexts.count - 1 {
                section.activeContextIndex++
                lexer.setPosition(section.position)
                return
            }
        default:
            // Invalid token, report error
            stopParsing = true
            return
        }

        currentToken = lexer.getToken()
        if currentToken.type != .TagEnd {
            stopParsing = true
            return
        }
        // Section is done
        sectionStack.pop()
    }

    func parseTriple(beginToken: Token) {
        currentToken = lexer.getToken()
        // Expected tokens are optional identifier followed by closing tag
        switch currentToken.type {
        case .Identifier:
            // Validate and render (unescaped)
            renderToken(currentToken, escaped: false)
        case .TripleEnd:
            // Empty tag
            return
        default:
            // Invalid token, report error
            stopParsing = true
            return
        }

        // Check closing tag
        currentToken = lexer.getToken()
        if currentToken.type != .TripleEnd {
            stopParsing = true
            return
        }
    }

    // MARK: - Rendering

    func renderToken(token: Token, escaped: Bool = true) {
        // Rendering needs a target
        if renderTarget == nil {
            return
        }
        // Only render tokens if active section allows it
        let section = sectionStack.last!
        if !section.shouldRender {
            return
        }

        var text: String!
        switch token.type {
        case .Identifier:
            // Lookup identifier in current context
            let name = lexer.template.text.substringWithRange(token.textRange)
            let value = valueForIdentifier(name)
            if let valueString = value as? String {
                text = valueString
            } else {
                text = ""
            }
        case .StaticText:
            text = lexer.template.text.substringWithRange(token.textRange)
        default:
            // Token is not renderable
            return
        }
        // Write text to render target
        renderTarget!.renderText(escaped ? text.stringByEscapingXMLEntities : text)
    }

    // MARK: - Private methods

    private func valueForIdentifier(identifier: String) -> Any? {
        let section = sectionStack.last!
        let value = section.contexts[section.activeContextIndex][identifier]
        return value
    }
}
