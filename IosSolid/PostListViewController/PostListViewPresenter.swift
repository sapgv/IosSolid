//
//  PostListViewPresenter.swift
//  IosSolid
//
//  Created by Grigory Sapogov on 23.12.2023.
//

import Foundation
import CoreData

class PostListViewPresenter {
    
    weak var view: PostListViewController?
    
    private(set) var posts: [Post] = []
    
    func update() {
        
        DispatchQueue.global().async { [weak self] in
            
            Thread.sleep(forTimeInterval: 2)
            
            let array = Post.array
            
            self?.save(array: array) { error in
                
                if let error = error {
                    DispatchQueue.main.async {
                        self?.view?.showError(error: error)
                    }
                    return
                }

                self?.fetch { result in
                    
                    switch result {
                    case let .failure(error):
                        DispatchQueue.main.async {
                            self?.view?.showError(error: error)
                        }
                    case let .success(posts):
                        self?.posts = posts
                        DispatchQueue.main.async {
                            self?.view?.updateView()
                        }
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func save(array: [[String: Any]], completion: @escaping (Error?) -> Void) {

        DispatchQueue.global().async {

            do {

                let posts = array.map { Post(data: $0) }

                let encoder = JSONEncoder()

                let encoded = try encoder.encode(posts)

                UserDefaults.standard.set(encoded, forKey: UserDefaultStorage.postKey)
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

    func fetch(completion: @escaping (Swift.Result<[Post], Error>) -> Void) {

        DispatchQueue.global().async {

            do {

                guard let data = UserDefaults.standard.object(forKey: UserDefaultStorage.postKey) as? Data else {
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
