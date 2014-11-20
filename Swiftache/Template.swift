//
//  Template.swift
//  Swiftache
//
//  Copyright (c) 2014 Bjørn Olav Ruud. All rights reserved.
//  Licensed under the MIT License (MIT). See LICENSE.txt for details.
//

import Foundation

public class Template {
    public let text: NSString
    public let fileURL: NSURL?
    public let fileEncoding: NSStringEncoding?

    private let data: NSData!

    public init(text: String) {
        self.text = text
    }

    public init(fileURL: NSURL, encoding: NSStringEncoding) {
        self.fileURL = fileURL
        self.fileEncoding = encoding

        var dataError = NSErrorPointer()
        let possibleData: NSData? = NSData(contentsOfURL: fileURL, options: .DataReadingMappedAlways, error: dataError)
        data = possibleData ?? NSData()
        text = NSString(bytesNoCopy: UnsafeMutablePointer<Void>(data.bytes), length: data.length, encoding: encoding, freeWhenDone: false)!
    }

    public convenience init(fileURL: NSURL) {
        self.init(fileURL: fileURL, encoding: NSUTF8StringEncoding)
    }
}
