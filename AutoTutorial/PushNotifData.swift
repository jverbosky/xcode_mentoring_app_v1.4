//
//  PushNotifData.swift
//  Mined Minds Mentoring
//
//  Created by something on 5/17/17.
//  Copyright © 2017 Tula Ram Subba. All rights reserved.
//

import Foundation
import SwiftyPlistManager

class PushNotifData {

    let dataPlistName = "Login"
//    let usernameKey = "username"  // plist username key
//    let pneStatusKey = "pneStatus"  // push notification enablement status key
    let fcmIdKey = "fcmId"  // plist fcmId key
//    var usernameValue: String = ""  // plist username value to post to Sinatra app
//    var pneStatusValue: String = ""  // push notification enablement status value to post to Sinatra app
    var fcmIdValue: String = ""  // plist fcmID value to post to Sinatra app
    
    init(fcmIdValue: String) {
//        self.usernameValue = usernameValue  // plist username value to post to Sinatra app
//        self.pneStatusValue = pneStatusValue  // push notification enablement status value to post to Sinatra app
        self.fcmIdValue = fcmIdValue  // plist fcmID value to post to Sinatra app
    }
    
    
//    // Function to determine push notification enablement status
//    class func checkPneStatus() {
//        let notificationType = UIApplication.shared.currentUserNotificationSettings!.types
//        if notificationType == [] {
//            pneStatusValue = "0"
//            print("notifications are NOT enabled")
//        } else {
//            pneStatusValue = "1"
//            print("notifications are enabled")
//        }
//    }
    
    // Function to determine if plist is already populated
    func evaluatePlist(_ key:String, _ value:String) {
        
        // Run function to add key/value pairs if plist empty, otherwise run function to update values
        SwiftyPlistManager.shared.getValue(for: key, fromPlistWithName: self.dataPlistName) { (result, err) in
            if err != nil {
                self.populatePlist(key, value)
            } else {
                self.updatePlist(key, value)
            }
        }
    }
    
    // Function to populate empty plist file with specified key/value pair
    func populatePlist(_ key:String, _ value:String) {
        SwiftyPlistManager.shared.addNew(value, key: key, toPlistWithName: self.dataPlistName) { (err) in
            if err == nil {
                print("-------------> Value '\(value)' successfully added at Key '\(key)' into '\(self.dataPlistName).plist'")
            }
        }
    }
    
    // Function to update specified key/value pair in plist file
    func updatePlist(_ key:String, _ value:String) {
        SwiftyPlistManager.shared.save(value, forKey: key, toPlistWithName: self.dataPlistName) { (err) in
            if err == nil {
                print("------------------->  Value '\(value)' successfully saved at Key '\(key)' into '\(self.dataPlistName).plist'")
            }
        }
    }
    
//    // Function to read email key/value pairs out of plist
//    func readPlistEmail(_ key:Any) {
//        
//        // Retrieve value
//        SwiftyPlistManager.shared.getValue(for: key as! String, fromPlistWithName: dataPlistName) { (result, err) in
//            if err == nil {
//                guard let result = result else {
//                    print("-------------> The Value for Key '\(key)' does not exists.")
//                    return
//                }
//                usernameValue = result as! String
//                print("------------> The value for the emailValue variable is \(usernameValue).")
//            } else {
//                print("No key in there!")
//            }
//        }
//    }
    
//    // Function to read push notification enablement status key/value pairs out of plist
//    class func readPlistPneStatus(_ key:Any) {
//        
//        // Retrieve value
//        SwiftyPlistManager.shared.getValue(for: key as! String, fromPlistWithName: dataPlistName) { (result, err) in
//            if err == nil {
//                guard let result = result else {
//                    print("-------------> The Value for Key '\(key)' does not exists.")
//                    return
//                }
//                pneStatusValue = result as! String
//                print("------------> The value for the pneStatusValue variable is \(pneStatusValue).")
//            } else {
//                print("No key in there!")
//            }
//        }
//    }
    
    // Function to read fcmID key/value pairs out of plist
    func readPlistFcm(_ key:Any) {
        
        // Retrieve value
        SwiftyPlistManager.shared.getValue(for: key as! String, fromPlistWithName: self.dataPlistName) { (result, err) in
            if err == nil {
                guard let result = result else {
                    print("-------------> The Value for Key '\(key)' does not exists.")
                    return
                }
                self.fcmIdValue = result as! String
                print("------------> The value for the fcmIdValue variable is \(self.fcmIdValue).")
            } else {
                print("No key in there!")
            }
        }
    }
    
    // Function to asynchronously retrive plist values so login can continue without hanging app
    func retrievePlistValues() {
        
        if self.fcmIdValue == "" {
//        if usernameValue == "" {
            DispatchQueue.global(qos: .userInteractive).async {
//                self.readPlistEmail(self.usernameKey)  // update usernameValue with plist value
//                self.readPlistPneStatus(self.pneStatusKey)  // update pneStatusValue with plist value
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
        
//        let email = usernameValue
        let email = "newclass@test.com"    // ---------> static value for now
//        let pneStatus = pneStatusValue
        let pneStatus = "2"    // ---------> static value for now
        let fcmID = self.fcmIdValue
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
    
}
