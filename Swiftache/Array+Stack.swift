//
//  Stack.swift
//  Swiftache
//
//  Created by Bjørn Olav Ruud on 05.09.14.
//  Copyright (c) 2014 Bjørn Olav Ruud. All rights reserved.
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
