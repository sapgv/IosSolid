//
//  Api.swift
//  IosSolid
//
//  Created by Grigory Sapogov on 23.12.2023.
//

import Foundation

final class Api {
    
    func fetchApiData(completion: @escaping (Swift.Result<[[String: Any]], Error>) -> Void) {
        
        DispatchQueue.global().async { 
            
            Thread.sleep(forTimeInterval: 2)
            
            let array = Post.array
            
            DispatchQueue.main.async {
                
                completion(.success(array))
                
            }
            
        }
        
    }
    
}
