//
//  HomeViewController.swift
//  Office365SwiftDemo
//
//  Created by Priyanka Sen on 12/08/19.
//  Copyright © 2019 Priyanka Sen. All rights reserved.
//

import UIKit
import WebKit

class HomeViewController: UIViewController {
    
    @IBOutlet weak var notePage: WKWebView!
    
    var noteBook: Note?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        guard let urlStr = noteBook?.oneNoteWebUrl else {return}
        print("noteBookURI:", urlStr)
        let url = URL(string: urlStr)
        notePage.load(URLRequest(url: url!))
        notePage.navigationDelegate = self
        notePage.scrollView.bounces = false
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    
    @IBAction func buttonOnClick(_ sender: Any) {
        let btn = sender as! UIButton
        switch(btn.tag) {
        case 1:
            performSegue(withIdentifier: "goToList", sender: self)
        case 2:
            performSegue(withIdentifier: "goToNotes", sender: self)
        case 3:
            performSegue(withIdentifier: "goToTasks", sender: self)
        case 4:
            performSegue(withIdentifier: "goToFiles", sender: self)
        default:
            performSegue(withIdentifier: "goToList", sender: self)
        }
    }
    
    
}

extension HomeViewController : WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let credential = URLCredential(user: "psen@netwoven.com", password: "priy123!123", persistence: URLCredential.Persistence.forSession)
        //challenge.sender?.use(credential, for: challenge)
        //completionHandler(URLSession.AuthChallengeDisposition.useCredential, credential)
        completionHandler(.useCredential, credential)
    }
    
}
