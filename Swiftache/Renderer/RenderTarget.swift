//
//  RendererProtocol.swift
//  Swiftache
//
//  Created by Bjørn Olav Ruud on 05.09.14.
//  Copyright (c) 2014 Bjørn Olav Ruud. All rights reserved.
//

import Foundation

public protocol RenderTarget {
    var text: String { get }
    func renderText(text: String)
}
