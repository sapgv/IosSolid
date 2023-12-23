//
//  CDPost + CoreData.swift
//  IosSolid
//
//  Created by Grigory Sapogov on 23.12.2023.
//

import Foundation

extension CDPost {
    
    func fill(data: [String: Any]) {
        self.id = (data["id"] as? Int)?.int64 ?? 0
        self.title = data["title"] as? String ?? ""
        self.body = data["body"] as? String ?? ""
    }
    
}
