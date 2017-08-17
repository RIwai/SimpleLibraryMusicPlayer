//
//  NotificationCenter.swift
//  SimpleLibraryMusicPlayer
//
//  Created by Ryota Iwai on 2015/09/14.
//  Copyright (c) 2015年 Ryota Iwai. All rights reserved.
//

import Foundation

public enum NCEventKey: Int {
    case localMusicStarted
    case localMusicPaused
    case localMusicTrackDidChange
    case localMusicNoPlayableTrack
    case localMusicSeekByRemoteBegan
    case localMusicSeekByRemoteEnded
    case showPlayer
    case playVideo
    
    var name: String {
        get {
            switch self {
            case .localMusicStarted: return "LocalMusicStarted"
            case .localMusicPaused: return "LocalMusicPaused"
            case .localMusicTrackDidChange: return "LocalMusicTrackDidChange"
            case .localMusicNoPlayableTrack: return "localMusicNoPlayableTrack"
            case .localMusicSeekByRemoteBegan: return "localMusicSeekByRemoteBegan"
            case .localMusicSeekByRemoteEnded: return "localMusicSeekByRemoteEnded"
            case .showPlayer: return "ShowPlayer"
            case .playVideo: return "playVideo"
            }
        }
    }
}

public extension NotificationCenter {

    // MARK: Add
    class func addObserver(observer: AnyObject, selector: Selector, event: NCEventKey, object: AnyObject?) {
        self.default.addObserver(observer, selector: selector, name: NSNotification.Name(rawValue: event.name), object: object)
    }

    class func addObserver(observer: AnyObject, selector aSelector: Selector, name aName: String?, object anObject: AnyObject?) {
        self.default.addObserver(observer, selector: aSelector, name: aName.map { NSNotification.Name(rawValue: $0) }, object: anObject)
    }

    // MARK: Remove
    class func removeObserver(observer: AnyObject, event: NCEventKey, object: AnyObject?) {
        self.default.removeObserver(observer, name: NSNotification.Name(rawValue: event.name), object: object)
    }

    class func removeObserver(observer: AnyObject, name aName: String?, object anObject: AnyObject?) {
        self.default.removeObserver(observer, name: aName.map { NSNotification.Name(rawValue: $0) }, object: anObject)
    }

    class func removeObserver(observer: AnyObject) {
        self.default.removeObserver(observer)
    }

    // MARK: Post
    class func postNotificationEvent(event: NCEventKey, object: Any?) {
        self.default.post(name: NSNotification.Name(rawValue: event.name), object: object)
    }

    class func postNotificationEvent(event: NCEventKey, object: Any?, userInfo: [AnyHashable: Any]?) {
        self.default.post(name: NSNotification.Name(rawValue: event.name), object: object, userInfo: userInfo)
    }
}
