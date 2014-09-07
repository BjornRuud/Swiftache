//
//  Swiftache.swift
//  Swiftache
//
//  Copyright (c) 2014 Bjørn Olav Ruud. All rights reserved.
//  Licensed under the MIT License (MIT). See LICENSE.txt for details.
//

import Foundation

public typealias RenderContext = [String: Any]

public class Swiftache {
    public var template: Template?
    public var target: RenderTarget?
    public var context: RenderContext?
    public private(set) var error: ParseError?

    public init() {}

    public func render() -> Bool {
        error = nil
        if template == nil {
            return false
        }
        if target == nil {
            return false
        }
        let lexer = Lexer(template: template!)
        let ctx = context ?? RenderContext()
        let parser = Parser(lexer: lexer, target: target!)
        parser.parseWithContext(ctx)
        if let parseError = parser.parseError {
            error = parseError
            return false
        }

        return true
    }

    public func render(template: Template, context: RenderContext, target: RenderTarget? = nil) -> Bool {
        self.template = template
        self.context = context
        self.target = target ?? StringRenderTarget()
        return render()
    }

    public func render(text: String, context: RenderContext, target: RenderTarget? = nil) -> Bool {
        let template = Template(text: text)
        return render(template, context: context, target: target)
    }

    public func render(url: NSURL, context: RenderContext, target: RenderTarget? = nil, encoding: NSStringEncoding = NSUTF8StringEncoding) -> Bool {
        let template = Template(fileURL: url, encoding: encoding)
        return render(template, context: context, target: target)
    }
}
