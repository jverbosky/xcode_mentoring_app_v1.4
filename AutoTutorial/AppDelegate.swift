//
//  AppDelegate.swift
//  AutoTutorial
//
//  Created by Tula Ram Subba and John Verbosky on 5/9/17.
//  Copyright © 2017 Tula Ram Subba. All rights reserved.
//

import UIKit
import UserNotifications
import Firebase
import FirebaseAuth
import FBSDKCoreKit
import FBSDKLoginKit
import GoogleSignIn
import SwiftyPlistManager

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {

    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
    let dataPlistName = "Login"
    let usernameKey = "username"  // plist username key
    let pneStatusKey = "pneStatus"  // push notification enablement status key
    let fcmIdKey = "fcmId"  // plist fcmId key
    var usernameValue:String = ""  // plist username value to post to Sinatra app
    var pneStatusValue:String = ""  // push notification enablement status value to post to Sinatra app
    var fcmIdValue:String = ""  // plist fcmID value to post to Sinatra app

    // Function to handle actions when app launches
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Show a permission dialog on first run to register for push notifications
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            
            // For iOS 10 data message (sent via FCM)
            FIRMessaging.messaging().remoteMessageDelegate = self
            
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        // Configures a default Firebase app, raises an exception if any configuration step fails
        FIRApp.configure()
        
        // Add observer for InstanceID token refresh callback.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.tokenRefreshNotification),
                                               name: .firInstanceIDTokenRefresh,
                                               object: nil)
        
        // Initialize plist if present, otherwise copy over Login.plist file into app's Documents directory
        SwiftyPlistManager.shared.start(plistNames: [dataPlistName], logging: false)
        
        // Facebook login initialization
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // Google login initialization
        GIDSignIn.sharedInstance().clientID = FIRApp.defaultApp()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        
        return true
    }

    // Function to handle receipt of push notification from Firebase
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
    }
    
    // Function to handle receipt of push notification from Firebase with completion handler
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    // Function to retrieve Firebase token and call evaluatePlist function
    func tokenRefreshNotification(_ notification: Notification) {
        if let refreshedToken = FIRInstanceID.instanceID().token() {
            print("InstanceID token: \(refreshedToken)")
            evaluatePlist(refreshedToken)
            retrievePlistValues()
        }
        
        // Connect to FCM since connection may have failed when attempted before having a token.
        connectToFcm()
    }
    
    // Function to connect to Firebase
    func connectToFcm() {
        // Won't connect since there is no token
        guard FIRInstanceID.instanceID().token() != nil else {
            return
        }
        
        // Disconnect previous FCM connection if it exists.
        FIRMessaging.messaging().disconnect()
        
        FIRMessaging.messaging().connect { (error) in
            if error != nil {
                print("Unable to connect with FCM. \(error?.localizedDescription ?? "")")
            } else {
                print("Connected to FCM.")
            }
        }
    }
    
    // Function to determine if plist is already populated
    func evaluatePlist(_ fcmIdValue:String) {
        
        // Run function to add key/value pairs if plist empty, otherwise run function to update values
        SwiftyPlistManager.shared.getValue(for: fcmIdKey, fromPlistWithName: dataPlistName) { (result, err) in
            if err != nil {
                populatePlist(fcmIdKey, fcmIdValue)
            } else {
                updatePlist(fcmIdKey, fcmIdValue)
            }
        }
    }
    
    // Function to populate empty plist file with specified key/value pair
    func populatePlist(_ key:String, _ value:String) {
        SwiftyPlistManager.shared.addNew(value, key: key, toPlistWithName: dataPlistName) { (err) in
            if err == nil {
                print("-------------> Value '\(value)' successfully added at Key '\(key)' into '\(dataPlistName).plist'")
            }
        }
    }
    
    // Function to update specified key/value pair in plist file
    func updatePlist(_ key:String, _ value:String) {
        SwiftyPlistManager.shared.save(value, forKey: key, toPlistWithName: dataPlistName) { (err) in
            if err == nil {
                print("------------------->  Value '\(value)' successfully saved at Key '\(key)' into '\(dataPlistName).plist'")
            }
        }
    }

    // Function to read email key/value pairs out of plist
    func readPlistEmail(_ key:Any) {
        
        // Retrieve value
        SwiftyPlistManager.shared.getValue(for: key as! String, fromPlistWithName: dataPlistName) { (result, err) in
            if err == nil {
                guard let result = result else {
                    print("-------------> The Value for Key '\(key)' does not exists.")
                    return
                }
                usernameValue = result as! String
                print("------------> The value for the emailValue variable is \(usernameValue).")
            } else {
                print("No key in there!")
            }
        }
    }
    
    // Function to read push notification enablement status key/value pairs out of plist
    func readPlistPneStatus(_ key:Any) {
        
        // Retrieve value
        SwiftyPlistManager.shared.getValue(for: key as! String, fromPlistWithName: dataPlistName) { (result, err) in
            if err == nil {
                guard let result = result else {
                    print("-------------> The Value for Key '\(key)' does not exists.")
                    return
                }
                pneStatusValue = result as! String
                print("------------> The value for the pneStatusValue variable is \(pneStatusValue).")
            } else {
                print("No key in there!")
            }
        }
    }
    
    // Function to read fcmID key/value pairs out of plist
    func readPlistFcm(_ key:Any) {
        
        // Retrieve value
        SwiftyPlistManager.shared.getValue(for: key as! String, fromPlistWithName: dataPlistName) { (result, err) in
            if err == nil {
                guard let result = result else {
                    print("-------------> The Value for Key '\(key)' does not exists.")
                    return
                }
                fcmIdValue = result as! String
                print("------------> The value for the fcmIdValue variable is \(fcmIdValue).")
            } else {
                print("No key in there!")
            }
        }
    }   
    
    // Function to asynchronously retrive plist values so login can continue without hanging app
    func retrievePlistValues() {
        
        if usernameValue == "" {
            DispatchQueue.global(qos: .userInteractive).async {
                self.readPlistEmail(self.usernameKey)  // update usernameValue with plist value
                self.readPlistPneStatus(self.pneStatusKey)  // update pneStatusValue with plist value
                self.readPlistFcm(self.fcmIdKey)  // update fcmIdValue with plist value
                Thread.sleep(forTimeInterval: 3.0)
                self.retrievePlistValues()
            }
        } else {
            DispatchQueue.main.async {
                self.postData()
            }
        }
    }
    
    // Function to post email and Firebase token to Sinatra app
    func postData() {
        
        // var request = URLRequest(url: URL(string: "https://mm-pushnotification.herokuapp.com/post_id")!)  // test to project Heroku-hosted app
        var request = URLRequest(url: URL(string: "https://ios-post-proto-jv.herokuapp.com/post_id")!)  // test to prototype Heroku-hosted app
        
        let email = usernameValue
        let pneStatus = pneStatusValue
        let fcmID = fcmIdValue
        let postString = "email=\(email)&pne_status=\(pneStatus)&fcm_id=\(String(describing: fcmID))"
        
        print("-------------> POSTing data......")
        
        request.httpMethod = "POST"
        request.httpBody = postString.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(String(describing: error))")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
            }
            
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(String(describing: responseString))")
        }
        task.resume()
    }
    
    
    // Function to handle Facebook signin
    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        let handled = FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String!, annotation: options[UIApplicationOpenURLOptionsKey.annotation])
        
        GIDSignIn.sharedInstance().handle(url,
            sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplicationOpenURLOptionsKey.annotation])
        
        return handled
    }
    
    // Function to handle successful Google signin
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        print("Successfully logged into Google")
        
        let authentication = user.authentication
        let credential = FIRGoogleAuthProvider.credential(withIDToken: (authentication?.idToken)!,
                                                          accessToken: (authentication?.accessToken)!)
        
        FIRAuth.auth()?.signIn(with: credential, completion: { (user, error) in
            print("User Signed in to Firebase")
            
            let _: UIStoryboard = UIStoryboard(name:"Main", bundle: nil)
            
            self.window?.rootViewController?.performSegue(withIdentifier: "goToHome", sender: nil)
        })
        
    }
    
    // Function to handle disconnect from Google due to error
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        
    }

    // Function to trap errors during remote notification registration
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    // Function to connect to Firebase when app becomes active after being paused
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        connectToFcm()
    }
    
    // Function to disconnect from Firebase
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        FIRMessaging.messaging().disconnect()
        print("Disconnected from FCM.")
    }
    
    // Xcode template function
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    // Xcode template function
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    // Xcode template function
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

// iOS 10 message handling
@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        // Change this to your preferred presentation option
        completionHandler([])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler()
    }
}

// iOS 10 data message handling
extension AppDelegate : FIRMessagingDelegate {
    // Receive data message on iOS 10 devices while app is in the foreground.
    func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
        print(remoteMessage.appData)
    }
}
