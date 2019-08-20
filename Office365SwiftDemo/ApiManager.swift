//
//  ApiManager.swift
//  Office365SwiftDemo
//
//  Created by Niraj Tenany on 20/08/19.
//  Copyright © 2019 Priyanka Sen. All rights reserved.
//

import Foundation
import MSAL

class ApiManager {
    let kClientID = "eead42ea-0f4a-4f7d-b03a-145c69f11c5f"
    let kAuthority = "https://login.microsoftonline.com/common"
    
    // Additional variables for Auth and Graph API
    let kGraphURI = "https://graph.microsoft.com/v1.0/me/"
    let kScopes: [String] = ["https://graph.microsoft.com/user.read","https://graph.microsoft.com/Notes.ReadWrite.All"]
    let myNotesURI = "https://graph.microsoft.com/v1.0/me/onenote/notebooks"
    
    var accessToken = String()
    var applicationContext : MSALPublicClientApplication?
    
    func initMSAL() throws {
        
        guard let authorityURL = URL(string: kAuthority) else {
            return
        }
        
        let authority = try MSALAADAuthority(url: authorityURL)
        
        let msalConfiguration = MSALPublicClientApplicationConfig(clientId: kClientID, redirectUri: nil, authority: authority)
        applicationContext = try MSALPublicClientApplication(configuration: msalConfiguration)
    }
    
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
            return nil
            
        }
        
        return nil
    }
    
    @objc func callGraphAPI() {
        
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
                return
            }
            guard let result = result else {
                return
            }
            // #4
            self.accessToken = result.accessToken
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
                return
            }
            
            guard let result = result else {
                return
            }
            
            self.accessToken = result.accessToken
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
                return
            }
            
            guard let result = try? JSONSerialization.jsonObject(with: data!, options: []) else {
                
                return
            }
            
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
                return
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary else {
                
                return
            }
            guard let dictionary = json as? [String: Any] else {
                return
            }
            guard let valueArr = dictionary["value"] as? [[String: Any]] else {
                return
            }
            
            DispatchQueue.main.async {
                return valueArr
            }
            
            }.resume()
    }
}


