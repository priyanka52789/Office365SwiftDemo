//
//  Note.swift
//  Office365SwiftDemo
//
//  Created by Niraj Tenany on 19/08/19.
//  Copyright © 2019 Priyanka Sen. All rights reserved.
//

import Foundation

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
