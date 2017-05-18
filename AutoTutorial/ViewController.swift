//
//  ViewController.swift
//  AutoTutorial
//
//  Created by Tula Ram Subba and John C. Verbosky on 5/3/17.
//  Copyright © 2017 Tula Ram Subba and John C. Verbosky. All rights reserved.
//

import UIKit
import Firebase //to access firebase to app
import FirebaseAuth //to autorise from firebase
import FBSDKLoginKit // to access facebook login
import GoogleSignIn  // to access google login

class ViewController: UIViewController, FBSDKLoginButtonDelegate, GIDSignInUIDelegate {
    
    @IBOutlet weak var signInSelector: UISegmentedControl!
    @IBOutlet weak var signInLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    
    var isSignIn:Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize programmatic Facebook and Google buttons
        setupFacebookButtons()
        setupGoogleButtons()
    }
    
    // Function to load Google login button
    fileprivate func setupGoogleButtons() {
        let googleButton = GIDSignInButton()
        let screenSize:CGRect = UIScreen.main.bounds
        let screenHeight = screenSize.height //real screen height
        let newCenterY = screenHeight - googleButton.frame.height - 50
        googleButton.frame = CGRect(x: 16, y: newCenterY, width: view.frame.width - 32, height: 40)
        view.addSubview(googleButton)
        
        GIDSignIn.sharedInstance().uiDelegate = self
        print("------> setupGoogleButtons")
    }
    
    // Function to load Facebook login button
    fileprivate func setupFacebookButtons() {
        let loginButton = FBSDKLoginButton()
        let screenSize:CGRect = UIScreen.main.bounds
        let screenHeight = screenSize.height //real screen height
        let newCenterY = screenHeight - loginButton.frame.height - 20
        loginButton.frame = CGRect(x: 16, y: newCenterY, width: view.frame.width - 32, height: 40)
        view.addSubview(loginButton)
        
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
    
    // Function to load main page on successful Facebook login
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

            if let email = currentUser.email {
                PushNotifData.checkPneStatus()
                PushNotifData.evaluatePlist("username", String(describing: email))
                PushNotifData.retrievePlistValues()
                print("---------->Current user: \(String(describing: email))")
            } else {
                print("------>Error retrieving username")
            }
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
            
            PushNotifData.checkPneStatus()
            PushNotifData.evaluatePlist("username", email)
            PushNotifData.retrievePlistValues()
            
            if isSignIn {
                FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
                    if let u = user {
                        print("------->user: \(u)")
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
                        print("------->user: \(u)")
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
    
}

