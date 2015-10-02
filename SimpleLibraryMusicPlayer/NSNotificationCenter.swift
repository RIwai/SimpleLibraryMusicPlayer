//
//  NSNotificationCenter.swift
//  SimpleLibraryMusicPlayer
//
//  Created by Ryota Iwai on 2015/09/14.
//  Copyright (c) 2015年 Ryota Iwai. All rights reserved.
//

import Foundation

@objc public enum NCEventKey: Int {
    case LocalMusicStarted
    case LocalMusicPaused
    case LocalMusicTrackDidChange
    case LocalMusicNoPlayableTrack
    case LocalMusicSeekByRemoteBegan
    case LocalMusicSeekByRemoteEnded
    case ShowPlayer
    
    var name: String {
        get {
            switch self {
            case LocalMusicStarted: return "LocalMusicStarted"
            case LocalMusicPaused: return "LocalMusicPaused"
            case LocalMusicTrackDidChange: return "LocalMusicTrackDidChange"
            case LocalMusicNoPlayableTrack: return "LocalMusicNoPlayableTrack"
            case LocalMusicSeekByRemoteBegan: return "LocalMusicSeekByRemoteBegan"
            case LocalMusicSeekByRemoteEnded: return "LocalMusicSeekByRemoteEnded"
            case ShowPlayer: return "ShowPlayer"
            }
        }
    }
}

public extension NSNotificationCenter {

    // MARK: Add
    class func addObserver(observer: AnyObject, selector: Selector, event: NCEventKey, object: AnyObject?) {
        self.defaultCenter().addObserver(observer, selector: selector, name: event.name, object: object)
    }

    class func addObserver(observer: AnyObject, selector aSelector: Selector, name aName: String?, object anObject: AnyObject?) {
        self.defaultCenter().addObserver(observer, selector: aSelector, name: aName, object: anObject)
    }

    // MARK: Remove
    class func removeObserver(observer: AnyObject, event: NCEventKey, object: AnyObject?) {
        self.defaultCenter().removeObserver(observer, name: event.name, object: object)
    }

    class func removeObserver(observer: AnyObject, name aName: String?, object anObject: AnyObject?) {
        self.defaultCenter().removeObserver(observer, name: aName, object: anObject)
    }

    class func removeObserver(observer: AnyObject) {
        self.defaultCenter().removeObserver(observer)
    }

    // MARK: Post
    class func postNotificationEvent(event: NCEventKey, object: AnyObject?) {
        self.defaultCenter().postNotificationName(event.name, object: object)
    }
}
