//
//  Array+Stack.swift
//  Swiftache
//
//  Copyright (c) 2014 Bjørn Olav Ruud. All rights reserved.
//  Licensed under the MIT License (MIT). See LICENSE.txt for details.
//

import Foundation

// Stack behaviour for array
extension Array {
    mutating func push(element: T) {
        append(element)
    }

    mutating func pop() -> T? {
        return count > 0 ? removeLast() : nil
    }
}
