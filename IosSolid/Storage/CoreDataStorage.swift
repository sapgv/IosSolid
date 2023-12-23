//
//  CoreDataStorage.swift
//  IosSolid
//
//  Created by Grigory Sapogov on 23.12.2023.
//

import CoreData

final class CoreDataStorage {
    
    private let privateContext: NSManagedObjectContext
    
    init() {
        self.privateContext = Model.coreData.createChildContextFromCoordinator(for: .privateQueueConcurrencyType)
    }
    
    func save(array: [[String: Any]], completion: @escaping (Error?) -> Void) {
        
        self.privateContext.perform { [privateContext] in
            
            privateContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            
            for data in array {
                
                let cdPost = CDPost(context: privateContext)
                cdPost.fill(data: data)
                
            }
            
            Model.coreData.save(in: privateContext) { status in
                
                DispatchQueue.main.async {
                    switch status {
                    case .hasNoChanges, .saved:
                        completion(nil)
                    default:
                        completion(StorageError.saveFailure(CDPost.entityName))
                    }
                }
                
            }
            
        }
        
    }
    
    func fetch(completion: @escaping (Swift.Result<[Post], Error>) -> Void) {
        
        self.privateContext.perform { [privateContext] in
            
            let cdPosts = Model.coreData.fetch(entity: CDPost.entityName, in: privateContext) as? [CDPost] ?? []
            
            let posts = cdPosts.map { Post(cdPost: $0) }
            
            DispatchQueue.main.async {
                
                completion(.success(posts))
                
            }
            
        }
        
    }
    
}
