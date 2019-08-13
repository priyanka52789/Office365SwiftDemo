//
//  HomeViewController.swift
//  Office365SwiftDemo
//
//  Created by Priyanka Sen on 12/08/19.
//  Copyright © 2019 Priyanka Sen. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {
    
    var noteBookURI: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        print("noteBookURI:", noteBookURI)
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    

}
