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
        print("json : ", json ?? "default value")
        guard let displayName = json?["displayName"] as! String?,
            let id = json?["id"] as! String?,
            let links = json?["links"] as? [String:Any]?,
            let oneNoteClientUrlDic = links?["oneNoteClientUrl"] as? [String:Any]?,
            let oneNoteClientUrl = oneNoteClientUrlDic?["href"] as? String,
            let oneNoteWebUrlDic = links?["oneNoteWebUrl"] as? [String:Any]?,
            let oneNoteWebUrl = oneNoteWebUrlDic?["href"] as? String,
            let own = json?["self"] as! String?,
            let userRole = json?["userRole"] as! String? else {
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
    
    let kClientID = "eead42ea-0f4a-4f7d-b03a-145c69f11c5f"
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
            if myNotes.count>0{
                let homeVc:HomeViewController = segue.destination as! HomeViewController
                //let indexPath = self.tableView.indexPathForSelectedRow()
                let first : Note = myNotes[0]
                homeVc.noteBookURI = first.oneNoteWebUrl
            }
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
            
            guard let json = try? JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary else {
                
                self.updateLogging(text: "Couldn't deserialize result JSON")
                return
            }
            guard let dictionary = json as? [String: Any] else {
                return
            }
            guard let valueArr = dictionary["value"] as? [[String: Any]] else {
                return
            }
            for n in 0...valueArr.count-1 {
                let item : Note = Note.init(json: valueArr[n])!
                self.myNotes.append(item)
            }
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "goToHome", sender: self)
            }
            
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

