//
//  AppDelegate.swift
//  SimpleLibraryMusicPlayer
//
//  Created by Ryota Iwai on 2015/08/17.
//  Copyright (c) 2015年 Ryota Iwai. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(application: UIApplication, supportedInterfaceOrientationsForWindow window: UIWindow?) -> UIInterfaceOrientationMask {
        return [.Portrait, .Landscape]
    }
}

