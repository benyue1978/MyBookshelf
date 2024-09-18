//
//  Item.swift
//  MyBookshelf
//
//  Created by song.yue on 2024/9/18.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
