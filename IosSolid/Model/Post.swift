//
//  Post.swift
//  IosSolid
//
//  Created by Grigory Sapogov on 23.12.2023.
//

import Foundation

protocol IPost: Codable {
    
    var id: Int { get }
    
    var title: String { get }
    
    var body: String { get }
    
}

final class Post: Codable, IPost {
    
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

