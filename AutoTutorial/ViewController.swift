//
//  ViewController.swift
//  AutoTutorial
//
//  Created by Tula Ram Subba on 5/3/17.
//  Copyright © 2017 Tula Ram Subba. All rights reserved.
//

import UIKit
import Firebase //to access firebase to app
import FirebaseAuth //to autorise from firebase
import FBSDKLoginKit // to access facebook login
import GoogleSignIn  // to access google login
import SwiftyPlistManager

class ViewController: UIViewController, FBSDKLoginButtonDelegate, GIDSignInUIDelegate {
    
    @IBOutlet weak var signInSelector: UISegmentedControl!
    @IBOutlet weak var signInLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    
    var isSignIn:Bool = true
    let dataPlistName = "Login"
    let usernameKey = "username"  // plist username key
    let pneStatusKey = "pneStatus"  // push notification enablement status key
    let fcmIdKey = "fcmId"  // plist fcmId key
    var usernameValue:String = ""  // plist username value to post to Sinatra app
    var pneStatusValue:String = ""  // push notification enablement status value to post to Sinatra app
    var fcmIdValue:String = ""  // plist fcmID value to post to Sinatra app
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize plist if present, otherwise copy over Login.plist file into app's Documents directory
        SwiftyPlistManager.shared.start(plistNames: [dataPlistName], logging: false)
        
        // Initialize programmatic Facebook and Google buttons
        setupFacebookButtons()
        setupGoogleButtons()

    }
    
    // Function to load Google login button
    fileprivate func setupGoogleButtons() {
        let googleButton = GIDSignInButton()
        // googleButton.frame = CGRect(x: 16, y: 100, width: view.frame.width - 32, height: 40)
        googleButton.frame = CGRect(x: 16, y: 600, width: view.frame.width - 32, height: 40)
        view.addSubview(googleButton)
        
        GIDSignIn.sharedInstance().uiDelegate = self
        print("------> setupGoogleButtons")
    }
    
//    // Function to obtain email address on successful Google login
//    func googleSignIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!,
//                withError error: NSError!) {
//        if (error == nil) {
//            // Perform any operations on signed in user here.
//            // let userId = user.userID                  // For client-side use only!
//            // let idToken = user.authentication.idToken // Safe to send to the server
//            // let fullName = user.profile.name
//            // let givenName = user.profile.givenName
//            // let familyName = user.profile.familyName
//            let email = user.profile.email
//            print("---------->Current user: \(String(describing: email!))")
//            // self.usernameValue = email!
//        } else {
//            print("\(error.localizedDescription)")
//        }
//    }
    
    // Function to load Facebook login button
    fileprivate func setupFacebookButtons() {
        let loginButton = FBSDKLoginButton()
        view.addSubview(loginButton)
        // loginButton.frame = CGRect(x: 16, y: 50, width: view.frame.width - 32, height: 40)
        loginButton.frame = CGRect(x: 16, y: 550, width: view.frame.width - 32, height: 40)
        
        loginButton.delegate = self
        
        loginButton.readPermissions = ["email", "user_friends", "public_profile"]
    }
    
    // Function to handle Facebook logout
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("Logged out of Facebook")
    }
    
    // Function to handle Facebook button press
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if error != nil {
            print(error)
            return
        }
        showEmailAddress()
    }
    
    // Function to obtain email address and load main page on successful Facebook login
    func showEmailAddress() {
        let accessToken = FBSDKAccessToken.current()
        guard let accessTokenString = accessToken?.tokenString
            else {
                return
        }
        
        let credentials = FIRFacebookAuthProvider.credential(withAccessToken: accessTokenString)
        FIRAuth.auth()?.signIn(with: credentials, completion: {(user, error) in
            if error != nil {
                print("Something went wrong in FB user: ", error ?? "")
                return
            }
            print("Successfully logged in with user: ", user ?? "")
            self.viewDidAppear(true)
        })
    
        FBSDKGraphRequest(graphPath: "/me", parameters: ["fields": "id, name, email"]).start {
            (connection, result, err) in
            if err != nil {
                print("Failed to start graph request:", err ?? "")
                return
            }
            print(result ?? "")
        }
    }
    
    // Function to segue to homepage after authenticating via Facebook
    override func viewDidAppear(_ animated: Bool) {
        
        if FIRAuth.auth()?.currentUser != nil {
            self.performSegue(withIdentifier: "goToHome", sender: self)
            
            
            let currentUser = FIRAuth.auth()!.currentUser!
            print("------->Current user: \(String(describing: currentUser.email))")
            if let email = currentUser.email {
                self.usernameValue = String(describing: email)
            } else {
                self.usernameValue = "unknown"
            }
            self.checkPneStatus()
            self.evaluatePlist(self.pneStatusKey, self.pneStatusValue)
            self.evaluatePlist(self.usernameKey, self.usernameValue)
        }
    }

    // Function to handle button label (Sign In / Register)
    @IBAction func signInSelectorChanged(_ sender: UISegmentedControl) {
        isSignIn = !isSignIn
        
        if isSignIn {
            signInLabel.text = "Sign In"
            signInButton.setTitle("Sign In", for: .normal)
        }
        else {
            signInLabel.text = "Register"
            signInButton.setTitle("Register", for: .normal)
        }
    }
   
    // Function to handle actions when Sign In / Register button is tapped
    @IBAction func signInButtonTapped(_ sender: UIButton) {
        if let email = emailTextField.text, let password = passwordTextField.text {
            
            self.checkPneStatus()
            self.evaluatePlist(self.pneStatusKey, self.pneStatusValue)
            self.evaluatePlist(self.usernameKey, email)
            self.retrievePlistValues()
            
            if isSignIn {
                FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
                    if let u = user {
                        self.performSegue(withIdentifier: "goToHome", sender: self)
                        
                    }
                    else {
                        //Error: check error and show message
                    }
                })
            }
            else {
                FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
                    if let u = user {
                        self.performSegue(withIdentifier: "goToHome", sender: self)
                        
                    }
                })
            }
            
        }
    }
    
    // Function to handle email and password field selection
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    
    // Function to determine push notification enablement status
    func checkPneStatus() {
        let notificationType = UIApplication.shared.currentUserNotificationSettings!.types
        if notificationType == [] {
            pneStatusValue = "0"
            print("notifications are NOT enabled")
        } else {
            pneStatusValue = "1"
            print("notifications are enabled")
        }
    }
    
    // Function to determine if plist is already populated
    func evaluatePlist(_ key:String, _ value:String) {
        
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
        
        if fcmIdValue == "" {
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
    
}

