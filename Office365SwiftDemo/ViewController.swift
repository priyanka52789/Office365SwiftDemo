//
//  ViewController.swift
//  Office365SwiftDemo
//
//  Created by Priyanka Sen on 28/07/19.
//  Copyright © 2019 Priyanka Sen. All rights reserved.
//

import UIKit
import MSAL

struct Note {
    
    var displayName: String
    var id: String
    var oneNoteClientUrl: String
    var oneNoteWebUrl: String
    var own: String
    var userRole: String
    
    init?(json: [String:Any]?) {
        guard let results = json?["results"] as? [Any],
            let first = results[0] as? [String:Any],
            let displayName = first["displayName"] as! String?,
            let id = first["id"] as! String?,
            let links = first["links"] as? [String:Any]?,
            let oneNoteClientUrlDic = links?["oneNoteClientUrl"] as? [String:Any]?,
            let oneNoteClientUrl = oneNoteClientUrlDic?["href"] as? String,
            let oneNoteWebUrlDic = links?["oneNoteWebUrl"] as? [String:Any]?,
            let oneNoteWebUrl = oneNoteWebUrlDic?["href"] as? String,
            let own = first["self"] as! String?,
            let userRole = first["userRole"] as! String? else {
                return nil
        }
        self.displayName = displayName
        self.id = id
        self.oneNoteClientUrl = oneNoteClientUrl
        self.oneNoteWebUrl = oneNoteWebUrl
        self.own = own
        self.userRole = userRole
    }
}

class ViewController: UIViewController {
    
    let kClientID = ""
    let kAuthority = "https://login.microsoftonline.com/common"
    
    // Additional variables for Auth and Graph API
    let kGraphURI = "https://graph.microsoft.com/v1.0/me/"
    let kScopes: [String] = ["https://graph.microsoft.com/user.read","https://graph.microsoft.com/Notes.ReadWrite.All"]
    let myNotesURI = "https://graph.microsoft.com/v1.0/me/onenote/notebooks"
    
    var accessToken = String()
    var applicationContext : MSALPublicClientApplication?
    
    var myNotes: [Note] = []
    
    @IBOutlet weak var callGraphButton: UIButton!
    
    @IBOutlet weak var signOutButton: UIButton!
    
    @IBOutlet weak var loggingText: UITextView!
    
    
    @IBAction func callGraphOnClick(_ sender: Any) {
        callGraphAPI(sender as! UIButton)
    }
    
    @IBAction func signOutOnClick(_ sender: Any) {
        signOut(sender as! UIButton)
    }
    
    
    //    var loggingText: UITextView!
//    var signOutButton: UIButton!
//    var callGraphButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //initUI()
        
        do {
            try self.initMSAL()
        } catch let error {
            self.loggingText.text = "Unable to create Application Context \(error)"
        }

    }

    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        signOutButton.isEnabled = !self.accessToken.isEmpty
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "goToHome") {
            // pass data to next view
            let homeVc:HomeViewController = segue.destination as! HomeViewController
            //let indexPath = self.tableView.indexPathForSelectedRow()
            homeVc.noteBookURI = self.myNotes[0].own
        }
    }
    
}

extension ViewController {
    func initMSAL() throws {
        
        guard let authorityURL = URL(string: kAuthority) else {
            self.loggingText.text = "Unable to create authority URL"
            return
        }
        
        let authority = try MSALAADAuthority(url: authorityURL)
        
        let msalConfiguration = MSALPublicClientApplicationConfig(clientId: kClientID, redirectUri: nil, authority: authority)
        self.applicationContext = try MSALPublicClientApplication(configuration: msalConfiguration)
    }
}

extension ViewController {
    
    /**
     This will invoke the authorization flow.
     */
    
    @objc func callGraphAPI(_ sender: UIButton) {
        
        guard let currentAccount = self.currentAccount() else {
            // We check to see if we have a current logged in account.
            // If we don't, then we need to sign someone in.
            acquireTokenInteractively()
            return
        }
        
        acquireTokenSilently(currentAccount)
    }
    
    func acquireTokenInteractively() {
        
        guard let applicationContext = self.applicationContext else { return }
        // #1
        let parameters = MSALInteractiveTokenParameters(scopes: kScopes)
        // #2
        applicationContext.acquireToken(with: parameters) { (result, error) in
            // #3
            if let error = error {
                self.updateLogging(text: "Could not acquire token: \(error)")
                return
            }
            guard let result = result else {
                self.updateLogging(text: "Could not acquire token: No result returned")
                return
            }
            // #4
            self.accessToken = result.accessToken
            self.updateLogging(text: "Access token is \(self.accessToken)")
            self.updateSignOutButton(enabled: true)
            //self.getContentWithToken()
            self.getMyNotesWithToken()
        }
    }
    
    func acquireTokenSilently(_ account : MSALAccount!) {
        guard let applicationContext = self.applicationContext else { return }
        let parameters = MSALSilentTokenParameters(scopes: kScopes, account: account)
        
        applicationContext.acquireTokenSilent(with: parameters) { (result, error) in
            if let error = error {
                let nsError = error as NSError
                if (nsError.domain == MSALErrorDomain) {
                    if (nsError.code == MSALError.interactionRequired.rawValue) {
                        DispatchQueue.main.async {
                            self.acquireTokenInteractively()
                        }
                        return
                    }
                }
                self.updateLogging(text: "Could not acquire token silently: \(error)")
                return
            }
            
            guard let result = result else {
                self.updateLogging(text: "Could not acquire token: No result returned")
                return
            }
            
            self.accessToken = result.accessToken
            self.updateLogging(text: "Refreshed Access token is \(self.accessToken)")
            self.updateSignOutButton(enabled: true)
            //self.getContentWithToken()
            self.getMyNotesWithToken()
        }
    }
    
    
    func getContentWithToken() {
        // Specify the Graph API endpoint
        let url = URL(string: kGraphURI)
        var request = URLRequest(url: url!)
        
        // Set the Authorization header for the request. We use Bearer tokens, so we specify Bearer + the token we got from the result
        request.setValue("Bearer \(self.accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                self.updateLogging(text: "Couldn't get graph result: \(error)")
                return
            }
            
            guard let result = try? JSONSerialization.jsonObject(with: data!, options: []) else {
                
                self.updateLogging(text: "Couldn't deserialize result JSON")
                return
            }
            
            self.updateLogging(text: "Result from Graph: \(result))")
            
            }.resume()
    }
    
    func getMyNotesWithToken() {
        // Specify the Graph API endpoint
        let url = URL(string: myNotesURI)
        var request = URLRequest(url: url!)
        
        // Set the Authorization header for the request. We use Bearer tokens, so we specify Bearer + the token we got from the result
        request.setValue("Bearer \(self.accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                self.updateLogging(text: "Couldn't get graph result: \(error)")
                return
            }
            
            guard let result = try? JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary else {
                
                self.updateLogging(text: "Couldn't deserialize result JSON")
                return
            }
            print("result", result?["value"] ?? "default value")
            self.myNotes = result?["value"] as? [Note] ?? []
            //self.myNotes = result.value
            //self.updateLogging(text: "Result from Graph: \(result))")
            //self.performSegue(withIdentifier: "goToHome", sender: self)
            
            }.resume()
    }
    
}

extension ViewController {
    
    func currentAccount() -> MSALAccount? {
        
        guard let applicationContext = self.applicationContext else { return nil }
        
        // We retrieve our current account by getting the first account from cache
        // In multi-account applications, account should be retrieved by home account identifier or username instead
        
        do {
            let cachedAccounts = try applicationContext.allAccounts()
            if !cachedAccounts.isEmpty {
                return cachedAccounts.first
            }
        } catch let error as NSError {
            self.updateLogging(text: "Didn't find any accounts in cache: \(error)")
        }
        
        return nil
    }
    
    
    @objc func signOut(_ sender: UIButton) {
        
        guard let applicationContext = self.applicationContext else { return }
        
        guard let account = self.currentAccount() else { return }
        
        do {
            
            /**
             Removes all tokens from the cache for this application for the provided account
             
             - account:    The account to remove from the cache */
            
            try applicationContext.remove(account)
            self.loggingText.text = ""
            self.signOutButton.isEnabled = false
            
        } catch let error as NSError {
            
            self.updateLogging(text: "Received error signing account out: \(error)")
        }
    }
    
}

// MARK: UI Helpers
extension ViewController {
    
    func initUI() {
        // Add call Graph button
        callGraphButton  = UIButton()
        callGraphButton.translatesAutoresizingMaskIntoConstraints = false
        callGraphButton.setTitle("Call Microsoft Graph API", for: .normal)
        callGraphButton.setTitleColor(.blue, for: .normal)
        callGraphButton.addTarget(self, action: #selector(callGraphAPI(_:)), for: .touchUpInside)
        self.view.addSubview(callGraphButton)
        
        callGraphButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        callGraphButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 50.0).isActive = true
        callGraphButton.widthAnchor.constraint(equalToConstant: 300.0).isActive = true
        callGraphButton.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        
        // Add sign out button
        signOutButton = UIButton()
        signOutButton.translatesAutoresizingMaskIntoConstraints = false
        signOutButton.setTitle("Sign Out", for: .normal)
        signOutButton.setTitleColor(.blue, for: .normal)
        signOutButton.setTitleColor(.gray, for: .disabled)
        signOutButton.addTarget(self, action: #selector(signOut(_:)), for: .touchUpInside)
        self.view.addSubview(signOutButton)
        
        signOutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        signOutButton.topAnchor.constraint(equalTo: callGraphButton.bottomAnchor, constant: 10.0).isActive = true
        signOutButton.widthAnchor.constraint(equalToConstant: 150.0).isActive = true
        signOutButton.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        signOutButton.isEnabled = false
        
        // Add logging textfield
        loggingText = UITextView()
        loggingText.isUserInteractionEnabled = false
        loggingText.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(loggingText)
        
        loggingText.topAnchor.constraint(equalTo: signOutButton.bottomAnchor, constant: 10.0).isActive = true
        loggingText.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 10.0).isActive = true
        loggingText.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: 10.0).isActive = true
        loggingText.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 10.0).isActive = true
    }
    
    func updateLogging(text : String) {
        
        if Thread.isMainThread {
            self.loggingText.text = text
        } else {
            DispatchQueue.main.async {
                self.loggingText.text = text
            }
        }
    }
    
    func updateSignOutButton(enabled : Bool) {
        if Thread.isMainThread {
            self.signOutButton.isEnabled = enabled
        } else {
            DispatchQueue.main.async {
                self.signOutButton.isEnabled = enabled
            }
        }
    }


}

