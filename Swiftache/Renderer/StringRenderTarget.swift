//
//  StringRenderTarget.swift
//  Swiftache
//
//  Copyright (c) 2014 Bjørn Olav Ruud. All rights reserved.
//  Licensed under the MIT License (MIT). See LICENSE.txt for details.
//

import Foundation

public class StringRenderTarget {
    private var _text: String = ""
    private var renderable = true
}

extension StringRenderTarget: RenderTarget {
    public var isRenderable: Bool {
        get {
            return renderable
        }
        set {
            renderable = newValue
        }
    }
    public var text: String {
        return _text
    }

    public func renderText(text: String) {
        if !renderable {
            return
        }
        _text.extend(text)
    }
}
