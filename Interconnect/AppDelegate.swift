//
//  AppDelegate.swift
//  Interconnect
//
//  Created by Stefan Kruger on 18/02/2015.
//  Copyright (c) 2015 Stefan Kruger. All rights reserved.
//

import UIKit

var cloudant = Cloudant(database:"interconnect", username:"interconnect2015", key:"cassayphapposillychawath", password: "7oKKggvTCewahieAvVMtvi8v", error: nil)

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        cloudant!.startPullReplicationWithHandler {
            NSNotificationCenter.defaultCenter().postNotificationName("CDTPullReplicationCompleted", object: nil)
        }
        
        return true
    }

}

