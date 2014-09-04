//
//  Template.swift
//  Swiftache
//
//  Created by Bjørn Olav Ruud on 04.09.14.
//  Copyright (c) 2014 Bjørn Olav Ruud. All rights reserved.
//

import Foundation

public class Template {
    let text: NSString
    let fileURL: NSURL?
    let fileEncoding: NSStringEncoding?

    private let data: NSData!

    init(text: String) {
        self.text = text
    }

    init(fileURL: NSURL, encoding: NSStringEncoding) {
        self.fileURL = fileURL
        self.fileEncoding = encoding

        var dataError = NSErrorPointer()
        let possibleData: NSData? = NSData(contentsOfURL: fileURL, options: .DataReadingMappedAlways, error: dataError)
        data = possibleData ?? NSData()
        text = NSString(bytesNoCopy: UnsafeMutablePointer<Void>(data.bytes), length: data.length, encoding: encoding, freeWhenDone: false)
    }

    convenience init(fileURL: NSURL) {
        self.init(fileURL: fileURL, encoding: NSUTF8StringEncoding)
    }
}
