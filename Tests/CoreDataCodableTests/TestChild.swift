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

struct TestChild: Codable {
    
    var identifier: Identifier
    
    var parent: TestParent.Identifier?
    
    var parentToOne: TestParent.Identifier?
}

extension TestChild {
    
    struct Identifier: Codable, CoreDataIdentifier {
        
        typealias CoreData = TestChild
        
        var rawValue: UUID
        
        init(rawValue: UUID) {
            
            self.rawValue = rawValue
        }
    }
}

extension TestChild.Identifier: Equatable {
    
    static func == (lhs: TestChild.Identifier, rhs: TestChild.Identifier) -> Bool {
        
        return lhs.rawValue == rhs.rawValue
    }
}

extension TestChild: CoreDataCodable {
    
    static var identifierKey: String { return "identifier" }
    
    func findOrCreate(in context: NSManagedObjectContext) throws -> TestParentManagedObject {
        
        let identifier = self.identifier.rawValue as NSUUID
        
        let identifierProperty = "identifier"
        
        let entityName = "TestChild"
        
        let fetchRequest = NSFetchRequest<ManagedObject>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%K == %@", identifierProperty, identifier)
        fetchRequest.fetchLimit = 1
        fetchRequest.includesSubentities = false
        fetchRequest.returnsObjectsAsFaults = true
        
        if let existing = try context.fetch(fetchRequest).first {
            
            return existing
            
        } else {
            
            // create a new entity
            let newManagedObject = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as! ManagedObject
            
            // set resource ID
            newManagedObject.setValue(identifier, forKey: identifierProperty)
            
            return newManagedObject
        }
    }
}

public final class TestChildManagedObject: NSManagedObject {
    
    @NSManaged var identifier: UUID
    
    @NSManaged var parent: TestParentManagedObject?
    
    @NSManaged var parentToOne: TestParentManagedObject?
}
