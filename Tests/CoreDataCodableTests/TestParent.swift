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
    
    struct Identifier: Codable, RawRepresentable {
        
        var rawValue: Int64
        
        init(rawValue: Int64) {
            
            self.rawValue = rawValue
        }
    }
}

extension TestParent.Identifier: CoreDataIdentifier {
    
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
    
    static func findOrCreate(_ identifier: TestParent.Identifier, in managedObjectContext: NSManagedObjectContext) throws -> TestParentManagedObject {
        
        let identifier = identifier.rawValue as NSNumber
        
        let identifierProperty = "identifier"
        
        let entityName = "TestParent"
        
        let fetchRequest = NSFetchRequest<ManagedObject>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%K == %@", identifierProperty, identifier)
        fetchRequest.fetchLimit = 1
        fetchRequest.includesSubentities = false
        fetchRequest.returnsObjectsAsFaults = true
        
        if let existing = try managedObjectContext.fetch(fetchRequest).first {
            
            return existing
            
        } else {
            
            // create a new entity
            let newManagedObject = NSEntityDescription.insertNewObject(forEntityName: entityName, into: managedObjectContext) as! ManagedObject
            
            // set resource ID
            newManagedObject.setValue(identifier, forKey: identifierProperty)
            
            return newManagedObject
        }
    }
}

public final class TestParentManagedObject: NSManagedObject {
    
    @NSManaged var identifier: Int64
    
    @NSManaged var child: TestChildManagedObject?
    
    @NSManaged var children: Set<TestChildManagedObject>
}
