//
//  RenderTarget.swift
//  Swiftache
//
//  Copyright (c) 2014 Bjørn Olav Ruud. All rights reserved.
//  Licensed under the MIT License (MIT). See LICENSE.txt for details.
//

import Foundation

public protocol RenderTarget {
    var isRenderable: Bool { get set }
    var text: String { get }
    func renderText(text: String)
}
