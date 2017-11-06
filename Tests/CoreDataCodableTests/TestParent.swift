//
//  TestParent.swift
//  CoreDataCodable
//
//  Created by Alsey Coleman Miller on 11/2/17.
//  Copyright © 2017 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
import CoreDataCodable

struct TestParent: Codable, Unique {
    
    var identifier: Identifier
    
    var child: TestChild.Identifier?
    
    var children: [TestChild.Identifier]
}

extension TestParent {
    
    struct Identifier: Codable, RawRepresentable {
        
        var rawValue: Int64
        
        init(rawValue: Int64) {
            
            self.rawValue = rawValue
        }
    }
}

extension TestParent.Identifier: CoreDataIdentifier {
    
    init?(managedObject: NSManagedObject) {
        
        guard let managedObject = managedObject as? TestParentManagedObject
            else { return nil }
        
        self.rawValue = managedObject.identifier
    }
    
    func findOrCreate(in context: NSManagedObjectContext) throws -> NSManagedObject {
        
        return try TestParent.findOrCreate(self, in: context)
    }
}

extension TestParent.Identifier: Equatable {
    
    static func == (lhs: TestParent.Identifier, rhs: TestParent.Identifier) -> Bool {
        
        return lhs.rawValue == rhs.rawValue
    }
}

extension TestParent: CoreDataCodable {
    
    static var identifierKey: String { return "identifier" }
    
    static func findOrCreate(_ identifier: TestParent.Identifier, in context: NSManagedObjectContext) throws -> TestParentManagedObject {
        
        let identifier = identifier.rawValue as NSNumber
        
        let identifierProperty = "identifier"
        
        let entityName = "TestParent"
        
        return try context.findOrCreate(identifier: identifier, property: identifierProperty, entityName: entityName)
    }
}

final class TestParentManagedObject: NSManagedObject {
    
    @NSManaged var identifier: Int64
    
    @NSManaged var child: TestChildManagedObject?
    
    @NSManaged var children: Set<TestChildManagedObject>
}

extension TestParentManagedObject: DecodableManagedObject {
    
    var decodable: CoreDataCodable.Type { return TestParent.self }
    
    var decodedIdentifier: Any { return identifier }
}
