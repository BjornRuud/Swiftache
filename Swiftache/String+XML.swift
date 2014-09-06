//
//  String+HTML.swift
//  Swiftache
//
//  Created by Bjørn Olav Ruud on 05.09.14.
//  Copyright (c) 2014 Bjørn Olav Ruud. All rights reserved.
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