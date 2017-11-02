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

struct TestParent: Codable {
    
    var identifier: Identifier
    
    var child: TestChild.Identifier?
    
    var children: [TestChild.Identifier]
}

extension TestParent {
    
    struct Identifier: Codable, CoreDataIdentifier {
        
        typealias CoreData = TestParent
        
        var rawValue: UUID
        
        init(rawValue: UUID) {
            
            self.rawValue = rawValue
        }
    }
}

extension TestParent.Identifier: Equatable {
    
    static func == (lhs: TestParent.Identifier, rhs: TestParent.Identifier) -> Bool {
        
        return lhs.rawValue == rhs.rawValue
    }
}

extension TestParent: CoreDataCodable {
    
    static var identifierKey: String { return "identifier" }
    
    func findOrCreate(in context: NSManagedObjectContext) throws -> TestParentManagedObject {
        
        let identifier = self.identifier.rawValue as NSUUID
        
        let identifierProperty = "identifier"
        
        let entityName = "TestParent"
        
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

public final class TestParentManagedObject: NSManagedObject {
    
    @NSManaged var identifier: UUID
    
    @NSManaged var child: TestChildManagedObject?
    
    @NSManaged var children: Set<TestChildManagedObject>
}
