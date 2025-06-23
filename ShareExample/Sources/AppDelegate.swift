//
//  AppDelegate.swift
//  ScribbleForge
//
//  Created by vince on 06/24/2024.
//  Copyright (c) 2024 vince. All rights reserved.
//

import UIKit
//import DebugSwift
//import ScribbleForge

//var gd = Data()
//
//func memoryTestGrow() {
//    // Generate 1mb heap data.
//    let data: [UInt8] = .init(repeating: 2, count: 1024 * 1024 * 10)
//    gd.append(contentsOf: data)
//    
//    print(gd.count / 1024 / 1024, "MB")
//    
//    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//        memoryTestGrow()
//    }
//}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        DebugSwift.setup()
//        DebugSwift.show()
//        memoryTestGrow()
        window = UIWindow(frame: UIScreen.main.bounds)
        let homeVC = HomeVC()
        window?.rootViewController = homeVC
        window?.makeKeyAndVisible()
        return true
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
//        print("memory warning")
//        gd.removeAll()
    }
}
