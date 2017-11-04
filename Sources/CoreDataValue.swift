//
//  CoreDataValue.swift
//  CoreDataCodable
//
//  Created by Alsey Coleman Miller on 11/4/17.
//  Copyright © 2017 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

/// A value type representing a managed object.
public struct CoreDataObject {
    
    public var values: [String: CoreDataValue]
}

/// Possible values for Core Data properties
public enum CoreDataValue {
    
    case none
    case attribute(Attribute)
    case relationship(Relationship)
}

public enum CoreDataReference {
    
    case reference( )
}

public extension CoreDataValue {
    
    /// Core Data Attributes
    public enum Attribute {
        
        case bool(Bool)
        case int16(Int16)
        case int32(Int32)
        case int64(Int64)
        case double(Double)
        case float(Float)
        case decimal(Decimal)
        case string(String)
        case date(Date)
        case data(Data)
        
        // new attributes
        case uuid(UUID)
        case uri(URL)
    }
}

public extension CoreDataValue {
    
    /// Core Data Relationship
    public enum Relationship {
        
        case toOne(CoreDataIdentifier)
        case toMany([CoreDataIdentifier])
    }
}
/*
// MARK: - RawRepresentable

extension CoreDataValue: RawRepresentable {
    
    public init?(rawValue: Any?) {
        
        if let value = rawValue {
            
            if let attribute = Attribute(rawValue: value) {
                
                self = .attribute(attribute)
                
            } else if let relationship = Relationship(rawValue: value) {
                
                self = .relationship(relationship)
                
            } else {
                
                return nil
            }
            
        } else {
            
            self = .none
        }
    }
    
    public var rawValue: Any? {
        
        switch self {
        case .none:
            return nil
        case let .attribute(attribute): return attribute.rawValue
        case let .attribute(attribute): return attribute.rawValue
        }
    }
}

extension CoreDataValue.Attribute: RawRepresentable {
    
    public init?(rawValue: Any) {
        
    }
    
    public var rawValue: Any {
        
        
    }
}

extension CoreDataValue.Relationship: RawRepresentable {
    
    public init?(rawValue: Any) {
        
    }
    
    public var rawValue: Any {
        
        
    }
}
*/
public extension CoreDataObject {
    
    init(managedObject: NSManagedObject) {
        
        let keys = managedObject.entity.allKeys
        
        var values = [String: CoreDataValue].init(minimumCapacity: keys.count)
        
        // convert values
        for propertyName in keys {
            
            let rawValue = managedObject.value(forKey: propertyName)
            
            let value: CoreDataValue
            
            if rawValue == nil {
                
                value = .none
                
            } else if let attributeValue = rawValue as? Int16 {
                
                value = .attribute(.int16(attributeValue))
                
            } else if let attributeValue = rawValue as? Int32 {
                
                value = .attribute(.int32(attributeValue))
                
            } else if let attributeValue = rawValue as? Int64 {
                
                value = .attribute(.int64(attributeValue))
                
            } else if let attributeValue = rawValue as? Bool {
                
                value = .attribute(.bool(attributeValue))
                
            } else if let attributeValue = rawValue as? Float {
                
                value = .attribute(.float(attributeValue))
                
            } else if let attributeValue = rawValue as? Double {
                
                value = .attribute(.double(attributeValue))
                
            } else if let attributeValue = rawValue as? NSDecimalNumber {
                
                value = .attribute(.decimal(attributeValue as Decimal))
                
            } else if let attributeValue = rawValue as? String {
                
                value = .attribute(.string(attributeValue))
                
            } else if let attributeValue = rawValue as? Date {
                
                value = .attribute(.date(attributeValue))
                
            } else if let attributeValue = rawValue as? Data {
                
                value = .attribute(.data(attributeValue))
                
            } else if let attributeValue = rawValue as? UUID {
                
                value = .attribute(.uuid(attributeValue))
                
            } else if let attributeValue = rawValue as? URL {
                
                value = .attribute(.uri(attributeValue))
                
            } /*else if let managedObject = rawValue as? NSManagedObject {
                
                guard let decodable = managedObject as? DecodableManagedObject
                    else { fatalError("Cannot decode \(managedObject)") }
                
                value = .relationship(.toOne(decodable.id))
                
            } */else {
                
                fatalError("Invalid value: \(rawValue)")
            }
            
            values[propertyName] = value
        }
        
        // set properties
        self.values = values
    }
}

public extension NSManagedObject {
    
    
}
