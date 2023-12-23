//
//  StorageError.swift
//  IosSolid
//
//  Created by Grigory Sapogov on 23.12.2023.
//

import Foundation

enum StorageError: Error {
    
    case saveFailure(String)
    case deleteFailure(String)
    
}
