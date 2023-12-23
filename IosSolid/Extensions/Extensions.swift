//
//  Extensions.swift
//  IosSolid
//
//  Created by Grigory Sapogov on 23.12.2023.
//

import UIKit
import CoreData

extension UINavigationBar {
    
    static func restoreAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
}

extension UITabBar {
    
    static func restoreAppearance() {
        let appearance = UITabBarAppearance()
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
}

extension UITableView {
    
    static func restoreAppearance() {
        UITableView.appearance().sectionHeaderTopPadding = 0.0
    }
    
}

extension Error {
    
    var NSError: Foundation.NSError {
        return Foundation.NSError(domain: "App.NSError", code: 0, userInfo: [NSLocalizedDescriptionKey: self.localizedDescription])
    }
    
}

public extension NSManagedObject {
    
    static var entityName: String {
        return String(describing: self)
    }
    
}

extension Int64 {
    
    var int: Int {
        Int(self)
    }
    
}

extension Int {
    
    var int64: Int64 {
        Int64(self)
    }
    
}
