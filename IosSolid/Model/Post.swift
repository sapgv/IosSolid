//
//  Post.swift
//  IosSolid
//
//  Created by Grigory Sapogov on 23.12.2023.
//

import Foundation

final class Post: Codable {
    
    let id: Int
    
    let title: String
    
    let body: String
    
    init(id: Int, title: String, body: String) {
        self.id = id
        self.title = title
        self.body = body
    }
    
    init(data: [String: Any]) {
        self.id = data["id"] as? Int ?? 0
        self.title = data["title"] as? String ?? ""
        self.body = data["body"] as? String ?? ""
    }
    
    init(cdPost: CDPost) {
        self.id = cdPost.id.int
        self.title = cdPost.title ?? ""
        self.body = cdPost.body ?? ""
    }
    
}

