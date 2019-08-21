//
//  HomeViewController.swift
//  Office365SwiftDemo
//
//  Created by Priyanka Sen on 12/08/19.
//  Copyright © 2019 Priyanka Sen. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    
    
    @IBAction func logoutOnClick(_ sender: Any) {
        
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

