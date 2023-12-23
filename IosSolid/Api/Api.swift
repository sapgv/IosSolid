//
//  Api.swift
//  IosSolid
//
//  Created by Grigory Sapogov on 23.12.2023.
//

import Foundation

protocol IApi: AnyObject{
    
    func fetchApiData(completion: @escaping (Swift.Result<[[String: Any]], Error>) -> Void)
    
}

final class Api: IApi {
    
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
