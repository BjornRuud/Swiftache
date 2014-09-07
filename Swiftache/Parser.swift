//
//  Parser.swift
//  Swiftache
//
//  Created by Bjørn Olav Ruud on 03.09.14.
//  Copyright (c) 2014 Bjørn Olav Ruud. All rights reserved.
//

import Foundation

private let ParserErrorDomain = "net.bjornruud.Swiftache.Parser"
private let RootSectionName = "ROOT"

class Section {
    var name: String
    var contexts = [RenderContext]()
    var activeContextIndex = 0
    var position = 0
    var shouldRender = true

    init(name: String) {
        self.name = name
    }
}

public struct ParseError {
    public let error: NSError
    public let location: TextLocation
    public let template: Template
}

class Parser {
    let lexer: Lexer
    var renderTarget: RenderTarget?
    var template: Template {
        return lexer.template
    }

    private(set) var parseError: ParseError?

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

    func reset() {
        sectionStack = [Section]()
        lexer.reset()
        stopParsing = false
    }

    func resetError() {
        parseError = nil
    }

    // MARK: - Parsing

    func parseWithContext(context: RenderContext) {
        resetError()
        // Add root section
        let section = Section(name: RootSectionName)
        section.contexts.append(context)
        sectionStack.push(section)
        while !stopParsing {
            parseStart()
        }
        reset()
    }

    func parseStart() {
        // Valid tokens to start with are static text and opening tags
        currentToken = lexer.getToken()
        switch currentToken.type {
        case .EOF:
            stopParsing = true
            // End of file is an error if there are unprocessed sections
            if sectionStack.count > 1 {
                let section = sectionStack.last!
                let msg = NSLocalizedString(
                    "\(currentToken.type.toRaw()) token in middle of section \(section.name)",
                    comment: "EOF in middle of section")
                reportError(msg)
            }
        case .StaticText:
            renderToken(currentToken, escaped: false)
        case .TagBegin:
            parseTag(currentToken)
        case .TripleBegin:
            parseTriple(currentToken)
        default:
            // Invalid token
            let section = sectionStack.last!
            let msg = NSLocalizedString(
                "Invalid top level token \(currentToken.type.toRaw()) in section \(section.name)",
                comment: "Invalid token at top level in section")
            reportError(msg)
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
            // Not expected token
            reportExpectedTokenError(.Identifier, gotToken: currentToken.type)
            return
        }
        let contentToken = currentToken

        // Verify end token
        currentToken = lexer.getToken()
        if currentToken.type != .TagEnd {
            reportExpectedTokenError(.TagEnd, gotToken: currentToken.type)
            return
        }

        renderToken(contentToken, escaped: escape)
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
            let msg = NSLocalizedString(
                "Invalid token \(currentToken.type.toRaw()) in comment",
                comment: "Invalid token in comment")
            reportError(msg)
            return
        }

        currentToken = lexer.getToken()
        if currentToken.type != .TagEnd {
            reportExpectedTokenError(.TagEnd, gotToken: currentToken.type)
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
            let name = template.text.substringWithRange(currentToken.textRange)
            fileURL = NSBundle.mainBundle().URLForResource(name, withExtension: nil)
            if fileURL == nil {
                // File not found
                // FIXME: Should this be an error?
            }
        default:
            // Invalid token, report error
            let msg = NSLocalizedString(
                "Unexpected token \(currentToken.type.toRaw()) in partial",
                comment: "Unexpected token in partial")
            reportError(msg)
            return
        }

        currentToken = lexer.getToken()
        if currentToken.type != .TagEnd {
            reportExpectedTokenError(.TagEnd, gotToken: currentToken.type)
            return
        }

        // Create parser for included template and parse it
        if fileURL == nil {
            return
        }
        let partialTemplate = Template(fileURL: fileURL!)
        let partialLexer = Lexer(template: partialTemplate)
        let partialParser = Parser(lexer: partialLexer)
        partialParser.renderTarget = renderTarget
        // Partials use the root context
        partialParser.parseWithContext(sectionStack[0].contexts[0])
        if let error = partialParser.parseError {
            parseError = ParseError(error: error.error, location: error.location, template: error.template)
            stopParsing = true
        }
    }

    func parseSection(beginToken: Token, typeToken: Token) {
        let inverted = typeToken.type == .SectionBeginInverted ? true : false

        currentToken = lexer.getToken()
        var section: Section!
        // Expected tokens are section name followed by closing tag
        switch currentToken.type {
        case .Identifier:
            let sectionName = template.text.substringWithRange(currentToken.textRange)
            section = Section(name: sectionName)

            // Parent doesn't render, neither does child
            let parentSection = sectionStack.last!
            if !parentSection.shouldRender {
                section.shouldRender = false
                break
            }

            // Look for section in current context
            let sectionValue = valueForIdentifier(sectionName)
            // Sections are activated by a bool, a context or an array
            if sectionValue == nil {
                section.shouldRender = inverted
                section.contexts = parentSection.contexts
            }
            else if let boolValue = sectionValue as? Bool {
                section.shouldRender = inverted ? !boolValue : boolValue
                // Section with bool uses parent context
                section.contexts = parentSection.contexts
            }
            else if let contextValue = sectionValue as? RenderContext {
                section.contexts.append(contextValue)
                section.shouldRender = contextValue.count == 0 ? inverted : !inverted
            }
            else if let arrayValue = sectionValue as? [RenderContext] {
                section.contexts.extend(arrayValue)
                section.shouldRender = section.contexts.count == 0 ? inverted : !inverted
            }
            else {
                // Section value type is not supported
                section.shouldRender = inverted
            }
        default:
            // Unexpected token, report error
            reportExpectedTokenError(.Identifier, gotToken: currentToken.type)
            return
        }

        currentToken = lexer.getToken()
        if currentToken.type != .TagEnd {
            reportExpectedTokenError(.TagEnd, gotToken: currentToken.type)
            return
        }

        section.position = currentToken.textRange.location + currentToken.textRange.length
        sectionStack.push(section)
    }

    func parseSectionEnd(beginToken: Token) {
        currentToken = lexer.getToken()
        var section: Section!
        switch currentToken.type {
        case .Identifier:
            section = sectionStack.last
            let sectionName = template.text.substringWithRange(currentToken.textRange)
            if sectionName != section.name {
                // End of wrong section
                let msg = NSLocalizedString(
                    "Found end of section \(sectionName), expected end of section \(section.name)",
                    comment: "End of wrong section")
                reportError(msg)
                return
            }
        default:
            // Unexpected token, report error
            reportExpectedTokenError(.Identifier, gotToken: currentToken.type)
            return
        }

        currentToken = lexer.getToken()
        if currentToken.type != .TagEnd {
            reportExpectedTokenError(.TagEnd, gotToken: currentToken.type)
            return
        }

        // Section is done, see if we need another iteration
        if section.activeContextIndex < section.contexts.count - 1 {
            section.activeContextIndex++
            lexer.setPosition(section.position)
            return
        }
        sectionStack.pop()
    }

    func parseTriple(beginToken: Token) {
        currentToken = lexer.getToken()
        // Expected tokens are optional identifier followed by closing tag
        var contentToken: Token!
        switch currentToken.type {
        case .Identifier:
            contentToken = currentToken
        case .TripleEnd:
            // Empty tag
            return
        default:
            // Invalid token, report error
            reportExpectedTokenError(.Identifier, gotToken: currentToken.type)
            return
        }

        // Check closing tag
        currentToken = lexer.getToken()
        if currentToken.type != .TripleEnd {
            reportExpectedTokenError(.TripleEnd, gotToken: currentToken.type)
            return
        }

        renderToken(contentToken, escaped: false)
    }

    // MARK: - Rendering

    func renderToken(token: Token, escaped: Bool = true) {
        // Rendering needs a target marked as renderable
        if renderTarget == nil || renderTarget!.isRenderable == false {
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
            let name = template.text.substringWithRange(token.textRange)
            let value = valueForIdentifier(name)
            if let valueString = value as? String {
                text = valueString
            } else {
                text = ""
            }
        case .StaticText:
            text = template.text.substringWithRange(token.textRange)
        default:
            // Token is not renderable
            return
        }
        // Write text to render target
        renderTarget!.renderText(escaped ? text.stringByEscapingXMLEntities : text)
    }

    // MARK: - Private methods

    private func reportError(message: String, stop: Bool = true) {
        let error = NSError(domain: ParserErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: message])
        parseError = ParseError(error: error, location: lexer.textLocationForRange(currentToken.textRange), template: lexer.template)
        stopParsing = stop
    }

    private func reportExpectedTokenError(expectedToken: TokenType, gotToken: TokenType, stop: Bool = true) {
        let msg = NSLocalizedString(
            "Expected \(expectedToken.toRaw()) token, got \(gotToken.toRaw())",
            comment: "Expected token error")
        reportError(msg, stop: stop)
    }

    private func valueForIdentifier(identifier: String) -> Any? {
        let section = sectionStack.last!
        let value = section.contexts[section.activeContextIndex][identifier]
        return value
    }
}
