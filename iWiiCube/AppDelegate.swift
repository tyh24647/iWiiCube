///
///  AppDelegate
///
///  Created by Tyler Hostager on 1/7/19.
///  Copyright © 2019 Tyler Hostager. All rights reserved.
///

import UIKit
import Foundation
import Darwin

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let kUserDefaults = UserDefaults(suiteName: "group.com.tyhostager.iWiiCube")!
    private let kStandardUserDefaults = UserDefaults(suiteName: "$(TeamIdentifierPrefix).group.com.tyhostager.iWiiCube")

    var window: UIWindow?
    public static var documentsPath: String!
    public static var libraryPath: String!
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        if FileManager.default.fileExists(atPath: AppDelegate.documentsPath) {
            do {
                try FileManager.default.createDirectory(atPath: AppDelegate.documentsPath, withIntermediateDirectories: true, attributes: nil)
            } catch let e {
                print("ERROR: Unable to create directory at the requested path.\n\tError details: \(e)")
            }
        }
        
        /*
        UINavigationBar.appearance().tintColor = .white
        UIApplication.shared.statusBarStyle = .lightContent
 */
        syscall(26, -1, 0, 0, 0)
        //syscall(SYS_ptrace, 0 /*PTRACE_TRACEME*/, 0, 0, 0)
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ app: UIApplication, open inputURL: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Ensure the URL is a file URL
        guard inputURL.isFileURL else { return false }
                
        // Reveal / import the document at the URL
        guard let documentBrowserViewController = window?.rootViewController as? DocumentBrowserViewController else { return false }

        documentBrowserViewController.revealDocument(at: inputURL, importIfNeeded: true) { (revealedDocumentURL, error) in
            if let error = error {
                // Handle the error appropriately
                print("Failed to reveal the document at URL \(inputURL) with error: '\(error)'")
                return
            }
            
            // Present the Document View Controller for the revealed URL
            documentBrowserViewController.presentDocument(at: revealedDocumentURL!)
        }

        return true
    }


}

