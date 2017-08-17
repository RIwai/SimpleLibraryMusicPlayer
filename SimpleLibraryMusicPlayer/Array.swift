//
//  Array.swift
//  SimpleLibraryMusicPlayer
//
//  Created by Ryota Iwai on 2015/09/15.
//  Copyright (c) 2015年 Ryota Iwai. All rights reserved.
//

import Foundation

extension Array {

    mutating func shuffle() {
        for index in 0..<self.count {
            let random = Int(arc4random_uniform(UInt32(index)))
            if random != index {
                self.swapAt(index, random)
            }
        }
    }

}
