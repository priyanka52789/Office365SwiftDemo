//
//  NotesViewController.swift
//  Office365SwiftDemo
//
//  Created by Niraj Tenany on 20/08/19.
//  Copyright © 2019 Priyanka Sen. All rights reserved.
//

import UIKit

class NotesViewController: UIViewController {

    var allNotes: [Note] = []
    
    @IBOutlet var notesTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension NotesViewController : UITableViewDelegate {
    
}

extension NotesViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allNotes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.textLabel?.text = allNotes[0].displayName
        return cell
    }
    
    
}
