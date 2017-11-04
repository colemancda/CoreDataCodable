//
//  CoreDataExtensions.swift
//  CoreDataCodable
//
//  Created by Alsey Coleman Miller on 11/3/17.
//  Copyright © 2017 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

extension NSEntityDescription {
    
    func contains <Key: CodingKey> (key: Key) -> Bool {
        
        return self.allKeys.contains(key.stringValue)
    }
    
    var allKeys: [String] {
        
        // all properties plus
        return self.properties.map { $0.name } + (self.superentity?.allKeys ?? [])
    }
}
