//
//  TestUtils.swift
//  Swiftache
//
//  Created by Bjørn Olav Ruud on 07.09.14.
//  Copyright (c) 2014 Bjørn Olav Ruud. All rights reserved.
//

import Foundation

func cachesURL() -> NSURL {
    let fm = NSFileManager.defaultManager()
    let url = fm.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
    return url
}

func documentsURL() -> NSURL {
    let fm = NSFileManager.defaultManager()
    let url = fm.URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).first! as NSURL
    return url
}

func newLexer(url: NSURL) -> Lexer {
    let template = Template(fileURL: url)
    return Lexer(template: template)
}

func newLexer(text: String) -> Lexer {
    let template = Template(text: text)
    return Lexer(template: template)
}

func newParser(text: String, target: RenderTarget = StringRenderTarget()) -> Parser {
    let template = Template(text: text)
    let lexer = Lexer(template: template)
    return Parser(lexer: lexer, target: target)
}

func newParser(url: NSURL, target: RenderTarget = StringRenderTarget()) -> Parser {
    let template = Template(fileURL: url)
    let lexer = Lexer(template: template)
    return Parser(lexer: lexer, target: target)
}
