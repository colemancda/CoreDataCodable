//
//  CoreDataCodable.swift
//  ColemanCDA
//
//  Created by Alsey Coleman Miller on 11/1/17.
//  Copyright © 2017 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

/// Specifies how a type can be encoded to be stored with Core Data.
public protocol CoreDataCodable: Codable {
    
    associatedtype ManagedObject: NSManagedObject
    
    associatedtype Identifier: CoreDataIdentifier
    
    static var identifierKey: String { get }
    
    var identifier: Identifier { get }
    
    /// Find or create
    static func findOrCreate(_ identifier: Identifier, in managedObjectContext: NSManagedObjectContext) throws -> ManagedObject
}

extension CoreDataCodable {
    
    @inline(__always)
    func findOrCreate(in managedObjectContext: NSManagedObjectContext) throws -> ManagedObject {
        
        return try Self.findOrCreate(self.identifier, in: managedObjectContext)
    }
    
    func encode(to managedObjectContext: NSManagedObjectContext) throws -> ManagedObject {
        
        let encoder = CoreDataEncoder(managedObjectContext: managedObjectContext)
        
        let managedObject = try encoder.encode(self)
        
        return managedObject
    }
}

public extension Collection where Iterator.Element: CoreDataCodable {
    
    func save(_ context: NSManagedObjectContext) throws -> Set<Self.Iterator.Element.ManagedObject> {
        
        var managedObjects = ContiguousArray<Iterator.Element.ManagedObject>()
        managedObjects.reserveCapacity(numericCast(self.count))
        
        for element in self {
            
            let managedObject = try element.encode(to: context)
            
            managedObjects.append(managedObject)
        }
        
        return Set(managedObjects)
    }
}

public protocol CoreDataIdentifier: Codable {
    
    func findOrCreate(in context: NSManagedObjectContext) throws -> NSManagedObject
}

internal extension Sequence where Iterator.Element: CodingKey {
    
    /// Convert CodingKey sequence into key path string.
    var keyPath: String {
        
        return self.reduce("", { $0 + "\($0.isEmpty ? "" : ".")" + $1.stringValue })
    }
}
