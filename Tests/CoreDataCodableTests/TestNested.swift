//
//  TestNested.swift
//  CoreDataCodable
//
//  Created by Alsey Coleman Miller on 11/5/17.
//  Copyright © 2017 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
import CoreDataCodable

struct TestNested: Codable, TestUnique {
    
    var identifier: TestNested.Identifier
        
    var children: [TestNested]
    
    var value: String = "Test value"
    
    var rawValue: Device = .iPhone
    
    init(identifier: TestNested.Identifier,
         children: [TestNested] = []) {
        
        self.identifier = identifier
        self.children = children
    }
}

extension TestNested {
    
    struct Identifier: Codable, RawRepresentable {
        
        var rawValue: String
        
        init(rawValue: String) {
            
            self.rawValue = rawValue
        }
    }
    
    enum Device: String, Codable {
        
        case iPhone, iPad, Mac
    }
}

extension TestNested.Identifier: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: String) {
        
        self.rawValue = value
    }
}

extension TestNested.Identifier: CoreDataIdentifier {
    
    init?(managedObject: NSManagedObject) {
        
        guard let managedObject = managedObject as? TestNestedManagedObject
            else { return nil }
        
        self.rawValue = managedObject.identifier
    }
    
    func findOrCreate(in context: NSManagedObjectContext) throws -> NSManagedObject {
        
        return try TestNested.findOrCreate(self, in: context)
    }
}

extension TestNested.Identifier: Equatable {
    
    static func == (lhs: TestNested.Identifier, rhs: TestNested.Identifier) -> Bool {
        
        return lhs.rawValue == rhs.rawValue
    }
}

extension TestNested: CoreDataCodable {
    
    static var identifierKey: CodingKey { return CodingKeys.identifier }
}

extension TestNested {
    
    static func findOrCreate(_ identifier: TestNested.Identifier, in context: NSManagedObjectContext) throws -> TestNestedManagedObject {
        
        let identifier = identifier.rawValue as NSString
        
        let identifierProperty = "identifier"
        
        let entityName = "TestNested"
        
        return try context.findOrCreate(identifier: identifier, property: identifierProperty, entityName: entityName)
    }
}

final class TestNestedManagedObject: NSManagedObject {
    
    @NSManaged var identifier: String
    
    @NSManaged var parent: TestNestedManagedObject?
    
    @NSManaged var children: Set<TestNestedManagedObject>
}
