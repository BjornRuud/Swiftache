//
//  FileRenderTarget.swift
//  Swiftache
//
//  Copyright (c) 2014 Bjørn Olav Ruud. All rights reserved.
//  Licensed under the MIT License (MIT). See LICENSE.txt for details.
//

import Foundation

public class FileRenderTarget {
    public let fileURL: NSURL?
    public let fileError: NSError?
    public let fileEncoding: NSStringEncoding

    private let ostream: NSOutputStream!

    public init(fileURL: NSURL, encoding: NSStringEncoding = NSUTF8StringEncoding, append: Bool = false) {
        fileEncoding = encoding
        // Verify url
        self.fileURL = fileURL
        // Create stream and open it
        ostream = NSOutputStream(URL: fileURL, append: append)
        ostream.open()
        if ostream.streamError != nil {
            fileError = ostream.streamError
        }
    }

    deinit {
        ostream.close()
    }
}

extension FileRenderTarget: RenderTarget {
    public var isRenderable: Bool {
        get {
            return ostream.streamStatus == .Open ? true : false
        }
        set {
            if !newValue {
                ostream.close()
            }
        }
    }

    public var text: String {
        if fileURL == nil {
            return ""
        }
        return NSString(contentsOfURL: fileURL!, encoding: fileEncoding, error: nil)!
    }

    public func renderText(text: String) {
        if !isRenderable {
            return
        }
        let data = text.dataUsingEncoding(fileEncoding, allowLossyConversion: true)
        if let data = data {
            ostream.write(UnsafePointer<UInt8>(data.bytes), maxLength: data.length)
        }
    }
}
