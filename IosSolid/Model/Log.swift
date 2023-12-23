//
//  Log.swift
//  Agronom
//
//  Created by Grigory Sapogov on 17.11.2023.
//

import Foundation

class Log {

    public static func debug(_ tag: String, _ message: String) {
        #if DEBUG
        print(tag + " : " + message)
        #endif
    }
    
    public static func debug(_ tag: String, _ error: NSError?) {
        debug(tag, error?.localizedDescription ?? "error")
    }
    
    public static func debug(_ tag: String, _ error: Error?) {
        debug(tag, error?.localizedDescription ?? "error")
    }

}
