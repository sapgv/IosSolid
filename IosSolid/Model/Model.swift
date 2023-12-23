//
//  Model.swift
//  IosSolid
//
//  Created by Grigory Sapogov on 23.12.2023.
//

import Foundation

final class Model {
    
    static var coreData: CoreData!
    
    static func setup() {
        self.coreData = CoreData(model: "Model")
    }
    
}
