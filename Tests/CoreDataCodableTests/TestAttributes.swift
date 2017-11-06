//
//  TestAttributes.swift
//  CoreDataCodable
//
//  Created by Alsey Coleman Miller on 11/2/17.
//  Copyright © 2017 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
import CoreDataCodable

struct TestAttributes: Codable, Unique {
    
    var identifier: Identifier
    
    var boolean: Bool
    
    var data: Data
    
    var date: Date
    
    var decimal: Decimal
    
    var double: Double
    
    var float: Float
    
    var int16: Int16
    
    var int32: Int32
    
    var int64: Int64
    
    var string: String
    
    var uri: URL
    
    var uuid: UUID
    
    var enumValue: TestEnum
    
    var optional: String?
}

extension TestAttributes {
    
    struct Identifier: Codable, RawRepresentable {
                
        var rawValue: String
        
        init(rawValue: String) {
            
            self.rawValue = rawValue
        }
    }
}

extension TestAttributes.Identifier: CoreDataIdentifier {
    
    init?(managedObject: NSManagedObject) {
        
        guard let managedObject = managedObject as? TestAttributesManagedObject
            else { return nil }
        
        self.rawValue = managedObject.identifier
    }
    
    func findOrCreate(in context: NSManagedObjectContext) throws -> NSManagedObject {
        
        return try TestAttributes.findOrCreate(self, in: context)
    }
}

extension TestAttributes.Identifier: Equatable {
    
    static func == (lhs: TestAttributes.Identifier, rhs: TestAttributes.Identifier) -> Bool {
        
        return lhs.rawValue == rhs.rawValue
    }
}

extension TestAttributes {
    
    enum TestEnum: String, Codable {
        
        case zero, one, two, three
    }
}

extension TestAttributes: CoreDataCodable {
    
    static var identifierKey: String { return "identifier" }
    
    static func findOrCreate(_ identifier: TestAttributes.Identifier, in context: NSManagedObjectContext) throws -> TestAttributesManagedObject {
        
        let identifier = identifier.rawValue as NSString
        
        let identifierProperty = "identifier"
        
        let entityName = "TestAttributes"
        
        return try context.findOrCreate(identifier: identifier, property: identifierProperty, entityName: entityName)
    }
}

final class TestAttributesManagedObject: NSManagedObject {
    
    @NSManaged var identifier: String
    
    @NSManaged var boolean: Bool
    
    @NSManaged var data: Data
    
    @NSManaged var date: Date
    
    @NSManaged var decimal: NSDecimalNumber //Decimal
    
    @NSManaged var double: Double
    
    @NSManaged var float: Float
    
    @NSManaged var int16: Int16
    
    @NSManaged var int32: Int32
    
    @NSManaged var int64: Int64
    
    @NSManaged var string: String
    
    @NSManaged var uri: URL
    
    @NSManaged var uuid: UUID
    
    @NSManaged var enumValue: String
    
    @NSManaged var optional: String?
}

extension TestAttributesManagedObject: DecodableManagedObject {
    
    var decodable: CoreDataCodable.Type { return TestAttributes.self }
    
    var decodedIdentifier: Any { return identifier }
}
