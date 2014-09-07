//
//  String+XML.swift
//  Swiftache
//
//  Copyright (c) 2014 Bjørn Olav Ruud. All rights reserved.
//  Licensed under the MIT License (MIT). See LICENSE.txt for details.
//

import Foundation

private let xmlEntities = [
    ("&", "&amp;"),
    ("\"", "&quot;"),
    ("'", "&apos;"),
    ("<", "&lt;"),
    (">", "&gt;")
]

extension String {
    var stringByEscapingXMLEntities: String {
        var text = NSMutableString(string: self)
        for (char, entity) in xmlEntities {
            text.replaceOccurrencesOfString(char, withString: entity, options: .LiteralSearch, range: NSRange(location: 0, length: text.length))
        }
        return text
    }

    var stringByUnescapingXMLEntities: String {
        var text = NSMutableString(string: self)
        for (char, entity) in xmlEntities.reverse() {
            text.replaceOccurrencesOfString(entity, withString: char, options: .LiteralSearch, range: NSRange(location: 0, length: text.length))
        }
        return text
    }
}
