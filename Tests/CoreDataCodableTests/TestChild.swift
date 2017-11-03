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

struct TestChild: Codable, Unique {
    
    var identifier: Identifier
    
    var parent: TestParent.Identifier?
    
    var parentToOne: TestParent.Identifier?
}

extension TestChild {
    
    struct Identifier: Codable, RawRepresentable {
        
        var rawValue: UUID
        
        init(rawValue: UUID) {
            
            self.rawValue = rawValue
        }
    }
}

extension TestChild.Identifier: CoreDataIdentifier {
    
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
    
    static var identifierKey: String { return "identifier" }
    
    static func findOrCreate(_ identifier: TestChild.Identifier, in context: NSManagedObjectContext) throws -> TestChildManagedObject {
        
        let identifier = identifier.rawValue as NSUUID
        
        let identifierProperty = "identifier"
        
        let entityName = "TestChild"
        
        return try context.findOrCreate(identifier: identifier, property: identifierProperty, entityName: entityName)
    }
}

public final class TestChildManagedObject: NSManagedObject {
    
    @NSManaged var identifier: UUID
    
    @NSManaged var parent: TestParentManagedObject?
    
    @NSManaged var parentToOne: TestParentManagedObject?
}
