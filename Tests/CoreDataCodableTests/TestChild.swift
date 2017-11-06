//
//  TestChild.swift
//  CoreDataCodable
//
//  Created by Alsey Coleman Miller on 11/2/17.
//  Copyright © 2017 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
import CoreDataCodable

struct TestChild: Codable, TestUnique {
    
    var identifier: Identifier
    
    var parent: TestParent.Identifier?
    
    var parentToOne: TestParent.Identifier?
}

extension TestChild {
    
    struct Identifier: Codable, RawRepresentable {
        
        var rawValue: String
        
        init(rawValue: String) {
            
            self.rawValue = rawValue
        }
    }
}

extension TestChild.Identifier: CoreDataIdentifier {
    
    init?(managedObject: NSManagedObject) {
        
        guard let managedObject = managedObject as? TestChildManagedObject
            else { return nil }
        
        self.rawValue = managedObject.identifier
    }
    
    func findOrCreate(in context: NSManagedObjectContext) throws -> NSManagedObject {
        
        return try TestChild.findOrCreate(self, in: context)
    }
}

extension TestChild.Identifier: Equatable {
    
    static func == (lhs: TestChild.Identifier, rhs: TestChild.Identifier) -> Bool {
        
        return lhs.rawValue == rhs.rawValue
    }
}

extension TestChild: CoreDataCodable {
    
    static var identifierKey: CodingKey { return CodingKeys.identifier }
    
    static func findOrCreate(_ identifier: TestChild.Identifier, in context: NSManagedObjectContext) throws -> TestChildManagedObject {
        
        let identifier = identifier.rawValue as NSString
        
        let identifierProperty = "identifier"
        
        let entityName = "TestChild"
        
        return try context.findOrCreate(identifier: identifier, property: identifierProperty, entityName: entityName)
    }
}

final class TestChildManagedObject: NSManagedObject {
    
    @NSManaged var identifier: String
    
    @NSManaged var parent: TestParentManagedObject?
    
    @NSManaged var parentToOne: TestParentManagedObject?
}

extension TestChildManagedObject: DecodableManagedObject {
    
    var decodable: CoreDataCodable.Type { return TestChild.self }
    
    var decodedIdentifier: Any { return identifier }
}
