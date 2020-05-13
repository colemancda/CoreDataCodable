//
//  CoreDataCodable.swift
//  ColemanCDA
//
//  Created by Alsey Coleman Miller on 11/1/17.
//  Copyright © 2017 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

// MARK: - CoreDataCodable

/// Specifies how a type can be encoded to be stored with Core Data.
public protocol CoreDataCodable: Codable {
    
    static var identifierKey: CodingKey { get }
    
    var coreDataIdentifier: CoreDataIdentifier { get }
}

extension CoreDataCodable {
    
    func encode(to managedObjectContext: NSManagedObjectContext) throws -> NSManagedObject {
        
        let encoder = CoreDataEncoder(managedObjectContext: managedObjectContext)
        
        let managedObject = try encoder.encode(self)
        
        return managedObject
    }
}

public extension Collection where Iterator.Element: CoreDataCodable {
    
    func save(_ context: NSManagedObjectContext) throws -> [NSManagedObject] {
        
        var managedObjects = ContiguousArray<NSManagedObject>()
        managedObjects.reserveCapacity(numericCast(self.count))
        
        for element in self {
            
            let managedObject = try element.encode(to: context)
            
            managedObjects.append(managedObject)
        }
        
        return Array(managedObjects)
    }
}

// MARK: - CoreDataIdentifier

public protocol CoreDataIdentifier: Codable {
    
    /// Find or create managed object from identifier in the specified managed object.
    func findOrCreate(in context: NSManagedObjectContext) throws -> NSManagedObject
    
    /// Failible initializer to create identifier from managed object.
    init?(managedObject: NSManagedObject)
}

public protocol DecodableManagedObject: class {
    
    var decodable: CoreDataCodable.Type { get }
    
    var decodedIdentifier: Any { get }
}

public extension Sequence where Iterator.Element: CoreDataIdentifier {
    
    @inline(__always)
    func findOrCreate(in context: NSManagedObjectContext) throws -> [NSManagedObject] {
        
        return try map { try $0.findOrCreate(in: context) }
    }
}

internal extension Sequence where Iterator.Element: CodingKey {
    
    /// Convert CodingKey sequence into key path string.
    var keyPath: String {
        
        return self.reduce("", { $0 + "\($0.isEmpty ? "" : ".")" + $1.stringValue })
    }
}
