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
    func findOrCreate(in context: NSManagedObjectContext) throws -> ManagedObject
}

extension CoreDataCodable {
    
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

public protocol CoreDataIdentifier: RawRepresentable, Equatable, Codable {
    
    associatedtype CoreData: CoreDataCodable
}
