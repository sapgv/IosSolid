//
//  UserDefaultStorage.swift
//  IosSolid
//
//  Created by Grigory Sapogov on 23.12.2023.
//

import Foundation

final class UserDefaultStorage: IStorage {
    
    static let postKey = "posts"
    
    func saveToStorage(array: [[String: Any]], completion: @escaping (Error?) -> Void) {
        
        DispatchQueue.global().async {
            
            do {
                
                let posts = array.map { Post(data: $0) }
                
                let encoder = JSONEncoder()
                
                let encoded = try encoder.encode(posts)
                
                UserDefaults.standard.set(encoded, forKey: Self.postKey)
                UserDefaults.standard.synchronize()
                
                DispatchQueue.main.async {
                    completion(nil)
                }
                
            }
            catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
            
        }
        
    }
    
    
    func fetchFromStorage(completion: @escaping (Swift.Result<[IPost], Error>) -> Void) {
        
        DispatchQueue.global().async {
            
            do {
                
                guard let data = UserDefaults.standard.object(forKey: Self.postKey) as? Data else {
                    DispatchQueue.main.async {
                        completion(.success([]))
                    }
                    return
                }
                
                let decoder = JSONDecoder()
                
                let posts = try decoder.decode([Post].self, from: data)
                
                DispatchQueue.main.async {
                    completion(.success(posts))
                }
                
            }
            catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
            
        }
        
    }
    
}
