//
//  TestFullfilledParent.swift
//  CoreDataCodable
//
//  Created by Alsey Coleman Miller on 11/2/17.
//  Copyright © 2017 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
import CoreDataCodable

struct TestFullfilledParent: Codable {
    
    typealias Identifier = TestParent.Identifier
    
    var identifier: Identifier
    
    var child: TestChild?
    
    var children: [TestChild]
}

extension TestFullfilledParent: CoreDataCodable {
    
    static var identifierKey: String { return "identifier" }
    
    static func findOrCreate(_ identifier: TestFullfilledParent.Identifier, in context: NSManagedObjectContext) throws -> TestParentManagedObject {
        
        let identifier = identifier.rawValue as NSNumber
        
        let identifierProperty = "identifier"
        
        let entityName = "TestParent"
        
        return try context.findOrCreate(identifier: identifier, property: identifierProperty, entityName: entityName)
    }
}

