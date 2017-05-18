//
//  PushNotifData.swift
//  Mined Minds Mentoring
//
//  Created by something on 5/17/17.
//  Copyright © 2017 John C. Verbosky. All rights reserved.
//

import Foundation
import SwiftyPlistManager

class PushNotifData {

    static let dataPlistName = "Login"
    static let usernameKey = "username"  // plist username key
    static let pneStatusKey = "pneStatus"  // push notification enablement status key
    static let fcmIdKey = "fcmId"  // plist fcmId key
    static var usernameValue: String = ""  // plist username value to post to Sinatra app
    static var pneStatusValue: String = ""  // push notification enablement status value to post to Sinatra app
    static var fcmIdValue: String = ""  // plist fcmID value to post to Sinatra app
    
    // Function to determine push notification enablement status
    class func checkPneStatus() {
        let notificationType = UIApplication.shared.currentUserNotificationSettings!.types
        if notificationType == [] {
            pneStatusValue = "0"
            evaluatePlist(pneStatusKey, pneStatusValue)
            print("notifications are NOT enabled")
        } else {
            pneStatusValue = "1"
            evaluatePlist(pneStatusKey, pneStatusValue)
            print("notifications are enabled")
        }
    }
    
    // Function to determine if plist is already populated
    class func evaluatePlist(_ key:String, _ value:String) {
        
        // Run function to add key/value pairs if plist empty, otherwise run function to update values
        SwiftyPlistManager.shared.getValue(for: key, fromPlistWithName: dataPlistName) { (result, err) in
            if err != nil {
                populatePlist(key, value)
            } else {
                updatePlist(key, value)
            }
        }
    }
    
    // Function to populate empty plist file with specified key/value pair
    class func populatePlist(_ key:String, _ value:String) {
        SwiftyPlistManager.shared.addNew(value, key: key, toPlistWithName: dataPlistName) { (err) in
            if err == nil {
                print("-------------> Value '\(value)' successfully added at Key '\(key)' into '\(dataPlistName).plist'")
            }
        }
    }
    
    // Function to update specified key/value pair in plist file
    class func updatePlist(_ key:String, _ value:String) {
        SwiftyPlistManager.shared.save(value, forKey: key, toPlistWithName: dataPlistName) { (err) in
            if err == nil {
                print("------------------->  Value '\(value)' successfully saved at Key '\(key)' into '\(dataPlistName).plist'")
            }
        }
    }
    
    // Function to read specified key/value pairs out of plist
    class func readPlistValue(_ key:Any) {
        
        // Retrieve value
        SwiftyPlistManager.shared.getValue(for: key as! String, fromPlistWithName: dataPlistName) { (result, err) in
            if err == nil {
                guard let result = result else {
                    print("-------------> The Value for Key '\(key)' does not exists.")
                    return
                }
                if key as! String == "username" {
                    usernameValue = result as! String
                } else if key as! String == "pneStatus" {
                    pneStatusValue = result as! String
                } else if key as! String == "fcmId" {
                    fcmIdValue = result as! String
                }
                print("------------> The value for the \(key) variable is \(result).")
            } else {
                print("No key in there!")
            }
        }
    }
    
    // Function to asynchronously retrive plist values so login can continue without hanging app
    class func retrievePlistValues() {
        
        if fcmIdValue == "" || usernameValue == "" {
            DispatchQueue.global(qos: .userInteractive).async {
                readPlistValue(usernameKey)  // update usernameValue with plist value
                readPlistValue(pneStatusKey)  // update pneStatusValue with plist value
                readPlistValue(fcmIdKey)  // update fcmIdValue with plist value
                Thread.sleep(forTimeInterval: 3.0)
                retrievePlistValues()
            }
        } else {
            DispatchQueue.main.async {
                readPlistValue(usernameKey)  // read again in case user logged out and back in with different method
                readPlistValue(pneStatusKey)
                readPlistValue(fcmIdKey)
                postData()
            }
        }
    }
    
    // Function to post email and Firebase token to Sinatra app
    class func postData() {
        
        var request = URLRequest(url: URL(string: "https://mm-pushnotification.herokuapp.com/post_id")!)  // test to project Heroku-hosted app
        // var request = URLRequest(url: URL(string: "https://ios-post-proto-jv.herokuapp.com/post_id")!)  // test to prototype Heroku-hosted app
        
        let email = usernameValue
        let pneStatus = pneStatusValue
        let fcmID = fcmIdValue
        let postString = "email=\(email)&pne_status=\(pneStatus)&fcm_id=\(String(describing: fcmID))"
        
        print("-------------> POSTing data......\(email)... \(pneStatus)... \(fcmID)...")
        
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
    
}
