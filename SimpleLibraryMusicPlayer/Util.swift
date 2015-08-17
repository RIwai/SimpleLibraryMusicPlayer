//
//  Util.swift
//  SimpleLibraryMusicPlayer
//
//  Created by Ryota Iwai on 2015/08/17.
//  Copyright (c) 2015年 Ryota Iwai. All rights reserved.
//

import Foundation

class Util: NSObject {

    class func timeString(secondTimes: NSTimeInterval?) -> String {
        
        if let unwrappedTime = secondTimes {
            if isnan(unwrappedTime) {
                return "00:00"
            }
            
            let min = Int(unwrappedTime / 60)
            let sec = Int(unwrappedTime % 60)
            
            return ((min < 10) ? "0" : "") + "\(min)" + ":" + ((sec < 10) ? "0" : "") + "\(sec)"
        } else {
            return "00:00"
        }
    }
}