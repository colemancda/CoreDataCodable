//
//  Encoder.swift
//  CoreDataCodable
//
//  Created by Alsey Coleman Miller on 11/2/17.
//  Copyright © 2017 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

public struct CoreDataEncoder {
    
    // MARK: - Properties
    
    /// The managed object used to encode values.
    public let managedObjectContext: NSManagedObjectContext
    
    /// Any contextual information set by the user for encoding.
    public var userInfo = [CodingUserInfoKey : Any]()
    
    /// Logger handler
    public var log: Log?
    
    // MARK: - Initialization
    
    public init(managedObjectContext: NSManagedObjectContext) {
        
        self.managedObjectContext = managedObjectContext
    }
    
    // MARK: - Methods
    
    public func encode<Encodable : CoreDataCodable>(_ encodable: Encodable) throws -> NSManagedObject {
        
        return try encode(encodable, codingPath: [])
    }
    
    fileprivate func encode<Encodable : CoreDataCodable>(_ encodable: Encodable, codingPath: [CodingKey]) throws -> NSManagedObject {
        
        // get managed object
        let managedObject = try encodable.findOrCreate(in: managedObjectContext)
        
        // create encoder for managed object
        let encoder = Encoder(managedObjectContext: managedObjectContext,
                              managedObject: managedObject,
                              encodable: encodable,
                              codingPath: codingPath,
                              userInfo: userInfo,
                              log: log)
        
        // encoder into container
        try encodable.encode(to: encoder)
        
        return managedObject
    }
}

// MARK: - Supporting Types

public extension CoreDataEncoder {
    
    public enum Error: Swift.Error {
        
        /// No key specified for container.
        case noKey
        
        /// Invalid selector (property doesn't exist)
        case invalidSelector(Selector)
        
        /// The type for the specified key does not match the type being encoded.
        case invalidType
    }
    
    public typealias Log = (String) -> ()
}

// MARK: - Encoder

fileprivate extension CoreDataEncoder {
    
    fileprivate class Encoder: Swift.Encoder {
        
        // MARK: - Properties
        
        /// The managed object used to encode values.
        public let managedObjectContext: NSManagedObjectContext
        
        /// The current managed object being encoded.
        public let managedObject: NSManagedObject
        
        /// The path of coding keys taken to get to this point in encoding.
        public fileprivate(set) var codingPath: [CodingKey]
        
        /// Any contextual information set by the user for encoding.
        public let userInfo: [CodingUserInfoKey : Any]
        
        /// The Swift encodable type being encoded.
        public let encodable: CoreDataCodable
        
        /// Logger
        public let log: Log?
        
        // MARK: - Initialization
        
        fileprivate init(managedObjectContext: NSManagedObjectContext,
                         managedObject: NSManagedObject,
                         encodable: CoreDataCodable,
                         codingPath: [CodingKey],
                         userInfo: [CodingUserInfoKey : Any],
                         log: Log?) {
            
            self.managedObjectContext = managedObjectContext
            self.managedObject = managedObject
            self.encodable = encodable
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.log = log
        }
        
        // MARK: - Methods
        
        public func container<Key>(keyedBy type: Key.Type) -> Swift.KeyedEncodingContainer<Key> where Key : CodingKey {
            
            let container = CoreDataEncoder.KeyedEncodingContainer<Key>(encoder: self)
            
            return Swift.KeyedEncodingContainer<Key>(container)
        }
        
        public func unkeyedContainer() -> Swift.UnkeyedEncodingContainer {
            
            return UnkeyedEncodingContainer(encoder: self)
        }
        
        public func singleValueContainer() -> Swift.SingleValueEncodingContainer {
            
            assert(self.codingPath.last != nil)
            
            return SingleValueEncodingContainer(encoder: self)
        }
    }
}

fileprivate extension CoreDataEncoder.Encoder {
    
     func set(_ value: NSObject?, forKey key: CodingKey) throws {
        
        // log
        log?("\(CoreDataEncoder.self): Will set \(value?.description ?? "nil") for key \"\(codingPath.reduce("", { $0 + "\($0.isEmpty ? "" : ".")" + $1.stringValue }))\"")
        
        // FIXME: test for valid property type
        
        let selector = Selector("set" + key.stringValue.capitalizingFirstLetter() + ":")
        
        let managedObject = self.managedObject
        
        // FIXME: Add option to throw or crash to improve performance
        
        guard managedObject.responds(to: selector) else {
            
            let context = EncodingError.Context(codingPath: codingPath,
                                                debugDescription: "No selector for the specified key.",
                                                underlyingError: CoreDataEncoder.Error.invalidSelector(selector))
            
            let error = EncodingError.invalidValue(value as Any, context)
            
            throw error
        }
        
        // FIXME: call setter selector instead of `setValue:forKey`
        //self.container.perform(selector, with: value)
        
        // set value on object
        managedObject.setValue(value, forKey: key.stringValue)
    }
}

// MARK: - Concrete Value Representations

private func box(_ value: Bool)   -> NSObject { return NSNumber(value: value) }
private func box(_ value: Int)    -> NSObject { return NSNumber(value: value) }
private func box(_ value: Int8)   -> NSObject { return NSNumber(value: value) }
private func box(_ value: Int16)  -> NSObject { return NSNumber(value: value) }
private func box(_ value: Int32)  -> NSObject { return NSNumber(value: value) }
private func box(_ value: Int64)  -> NSObject { return NSNumber(value: value) }
private func box(_ value: UInt)   -> NSObject { return NSNumber(value: value) }
private func box(_ value: UInt8)  -> NSObject { return NSNumber(value: value) }
private func box(_ value: UInt16) -> NSObject { return NSNumber(value: value) }
private func box(_ value: UInt32) -> NSObject { return NSNumber(value: value) }
private func box(_ value: UInt64) -> NSObject { return NSNumber(value: value) }
private func box(_ value: Float)  -> NSObject { return NSNumber(value: value) }
private func box(_ value: Double) -> NSObject { return NSNumber(value: value) }
private func box(_ value: String) -> NSObject { return NSString(string: value) }
private func box(_ date: Date)    -> NSObject { return date as NSDate }
private func box(_ data: Data)    -> NSObject { return data as NSData }
private func box(_ uuid: UUID)    -> NSObject { return uuid as NSUUID }
private func box(_ url: URL)      -> NSObject { return url as NSURL }
private func box(_ decimal: Decimal) -> NSObject { return decimal as NSDecimalNumber }

/*
// MARK: - ReferenceEncoder

fileprivate extension CoreDataEncoder {
    
    fileprivate final class ReferencingEncoder <Encodable: CoreDataCodable>: Encoder {
        
        /// A reference to the encoder we're writing to.
        fileprivate let encoder: CoreDataEncoder.Encoder<Encodable>
        
        fileprivate init(referencing encoder: Encoder<Encodable>, at index: Int, wrapping array: NSMutableArray) {
            self.encoder = encoder
            self.reference = .array(array, index)
            super.init(options: encoder.options, codingPath: encoder.codingPath)
            
            self.codingPath.append(_JSONKey(index: index))
        }
        
        func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
            
        }
        
        func unkeyedContainer() -> UnkeyedEncodingContainer {
 
        }
        
        func singleValueContainer() -> SingleValueEncodingContainer {
 
        }
    }
}
*/
// MARK: - KeyedEncodingContainer

fileprivate extension CoreDataEncoder {
    
    fileprivate struct KeyedEncodingContainer<K : CodingKey> : KeyedEncodingContainerProtocol {
        
        public typealias Key = K
        
        /// A reference to the encoder we're writing to.
        fileprivate let encoder: CoreDataEncoder.Encoder
        
        /// A reference to the container we're writing to.
        private var container: NSManagedObject {
            
            get { return encoder.managedObject }
        }
        
        /// The path of coding keys taken to get to this point in encoding.
        public private(set) var codingPath: [CodingKey] {
            
            get { return encoder.codingPath }
            
            mutating set { encoder.codingPath = newValue }
        }
        
        // Standard primitive types
        public mutating func encodeNil(forKey key: Key)               throws { try write(nil, forKey: key) }
        public mutating func encode(_ value: Bool, forKey key: Key)   throws { try write(box(value), forKey: key) }
        public mutating func encode(_ value: Int, forKey key: Key)    throws { try write(box(value), forKey: key) }
        public mutating func encode(_ value: Int8, forKey key: Key)   throws { try write(box(value), forKey: key) }
        public mutating func encode(_ value: Int16, forKey key: Key)  throws { try write(box(value), forKey: key) }
        public mutating func encode(_ value: Int32, forKey key: Key)  throws { try write(box(value), forKey: key) }
        public mutating func encode(_ value: Int64, forKey key: Key)  throws { try write(box(value), forKey: key) }
        public mutating func encode(_ value: UInt, forKey key: Key)   throws { try write(box(value), forKey: key) }
        public mutating func encode(_ value: UInt8, forKey key: Key)  throws { try write(box(value), forKey: key) }
        public mutating func encode(_ value: UInt16, forKey key: Key) throws { try write(box(value), forKey: key) }
        public mutating func encode(_ value: UInt32, forKey key: Key) throws { try write(box(value), forKey: key) }
        public mutating func encode(_ value: UInt64, forKey key: Key) throws { try write(box(value), forKey: key) }
        public mutating func encode(_ value: String, forKey key: Key) throws { try write(box(value), forKey: key) }
        public mutating func encode(_ value: Float, forKey key: Key) throws { try write(box(value), forKey: key) }
        public mutating func encode(_ value: Double, forKey key: Key) throws { try write(box(value), forKey: key) }
        
        // Custom
        private mutating func encode(_ value: Data, forKey key: Key) throws { try write(box(value), forKey: key) }
        private mutating func encode(_ value: Date, forKey key: Key) throws { try write(box(value), forKey: key) }
        private mutating func encode(_ value: UUID, forKey key: Key) throws { try write(box(value), forKey: key) }
        private mutating func encode(_ value: URL, forKey key: Key) throws { try write(box(value), forKey: key) }
        private mutating func encode(_ value: Decimal, forKey key: Key) throws { try write(box(value), forKey: key) }
        
        // Encodable
        public mutating func encode<T: Swift.Encodable>(_ value: T, forKey key: Key) throws {
            
            // override for CoreData supported native types that also are Encodable
            // and don't use encodable implementation
            
            // identifier or to-one relationship
            if let identifier = value as? CoreDataIdentifier {
                
                let encodable = encoder.encodable
                
                let identifierKey = type(of: encodable).identifierKey
                
                // identifier
                if key.stringValue == identifierKey {
                    
                    // skip value since we assume managed object is already faulted
                    assert(container.value(forKey: identifierKey) != nil, "No identifier set")
                    
                } else {
                    
                    // set relationship value
                    try setRelationship(identifier, forKey: key)
                }
                
            } else if let encodable = value as? CoreDataCodable {
                
                try setRelationship(encodable, forKey: key)
                
            } else if let array = value as? [CoreDataIdentifier] {
                
                try setRelationship(array, forKey: key)
                
            } else if let set = value as? Set<AnyHashable>,
                let array = Array(set) as? [CoreDataIdentifier] {
                
                try setRelationship(array, forKey: key)
                
            } else if let array = value as? [CoreDataCodable] {
                
                try setRelationship(array, forKey: key)
                
            } else if let set = value as? Set<AnyHashable>,
                let array = Array(set) as? [CoreDataCodable] {
                
                try setRelationship(array, forKey: key)
                
            } else if let value = value as? Data {
                
                try encode(value, forKey: key)
                
            } else if let value = value as? Date {
                
                try encode(value, forKey: key)
                
            } else if let value = value as? UUID {
                
                try encode(value, forKey: key)
                
            } else if let value = value as? URL {
                
                try encode(value, forKey: key)
                
            } else if let value = value as? Decimal {
                
                try encode(value, forKey: key)
                
            } else {
                
                // set coding key context
                codingPath.append(key)
                defer { codingPath.removeLast() }
                
                // get value
                try value.encode(to: encoder)
            }
        }
        
        public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> Swift.KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            
            fatalError()
        }
        
        public mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
            
            fatalError()
        }
        
        public mutating func superEncoder() -> Swift.Encoder {
            
            fatalError()
        }
        
        public mutating func superEncoder(forKey key: Key) -> Swift.Encoder {
            
            fatalError()
        }
        
        private mutating func write(_ value: NSObject?, forKey key: Key) throws {
            
            // set coding key context
            codingPath.append(key)
            defer { codingPath.removeLast() }
            
            // set value
            try encoder.set(value, forKey: key)
        }
        
        private mutating func setRelationship(_ identifiers: [CoreDataIdentifier], forKey key: Key) throws {
            
            let managedObjectContext = encoder.managedObjectContext
            
            let managedObjects = try identifiers.map { try $0.findOrCreate(in: managedObjectContext) }
            
            let isOrdered = self.encoder.managedObject.entity.relationshipsByName[key.stringValue]?.isOrdered ?? false
            
            let set: NSObject = isOrdered ? NSOrderedSet(array: managedObjects) : NSSet(array: managedObjects)
            
            // set value
            try write(set, forKey: key)
        }
        
        private mutating func setRelationship(_ encodables: [CoreDataCodable], forKey key: Key) throws {
            
            let managedObjects = try encodables.map { (try $0.findOrCreate(in: encoder.managedObjectContext), $0) }
            
            try managedObjects.forEach {
                
                // create encoder for managed object
                let encoder = Encoder(managedObjectContext: self.encoder.managedObjectContext,
                                      managedObject: $0,
                                      encodable: $1,
                                      codingPath: self.encoder.codingPath,
                                      userInfo: self.encoder.userInfo,
                                      log: self.encoder.log)
                
                // encoder into container
                try $1.encode(to: encoder)
            }
            
            let set = NSSet(array: managedObjects.map({ $0.0 }))
            
            // set value
            try write(set, forKey: key)
        }
        
        private mutating func setRelationship(_ identifier: CoreDataIdentifier, forKey key: Key) throws {
            
            // get managed object fault
            let managedObject = try identifier.findOrCreate(in: encoder.managedObjectContext)
            
            // set value
            try write(managedObject, forKey: key)
        }
        
        private mutating func setRelationship(_ encodable: CoreDataCodable, forKey key: Key) throws {
            
            let managedObject = try encodable.findOrCreate(in: self.encoder.managedObjectContext)
            
            // create encoder for managed object
            let newEncoder = Encoder(managedObjectContext: self.encoder.managedObjectContext,
                                  managedObject: managedObject,
                                  encodable: encodable,
                                  codingPath: self.encoder.codingPath,
                                  userInfo: self.encoder.userInfo,
                                  log: self.encoder.log)
            
            // encoder into container
            try encodable.encode(to: newEncoder)
            
            // set value
            try write(managedObject, forKey: key)
        }
    }
}

// MARK: - SingleValueEncodingContainer

fileprivate extension CoreDataEncoder.Encoder {
    
    fileprivate struct SingleValueEncodingContainer: Swift.SingleValueEncodingContainer {
        
        fileprivate let encoder: CoreDataEncoder.Encoder
        
        /// A reference to the container we're writing to.
        private var container: NSManagedObject {
            
            get { return encoder.managedObject }
        }
        
        public var codingPath: [CodingKey] {
            
            get { return encoder.codingPath }
        }
        
        public func encodeNil() throws {
            
            try write(nil)
        }
        
        public func encode(_ value: Bool) throws {
            
            try write(box(value))
        }
        
        public func encode(_ value: Int) throws {
            
            try write(box(value))
        }
        
        public func encode(_ value: Int8) throws {
            
            try write(box(value))
        }
        
        public func encode(_ value: Int16) throws {
            
            try write(box(value))
        }
        
        public func encode(_ value: Int32) throws {
            
            try write(box(value))
        }
        
        public func encode(_ value: Int64) throws {
            
            try write(box(value))
        }
        
        public func encode(_ value: UInt) throws {
            
            try write(box(value))
        }
        
        public func encode(_ value: UInt8) throws {
            
            try write(box(value))
        }
        
        public func encode(_ value: UInt16) throws {
            
            try write(box(value))
        }
        
        public func encode(_ value: UInt32) throws {
            
            try write(box(value))
        }
        
        public func encode(_ value: UInt64) throws {
            
            try write(box(value))
        }
        
        public func encode(_ value: String) throws {
            
            try write(box(value))
        }
        
        public func encode(_ value: Float) throws {
            
            try write(box(value))
        }
        
        public func encode(_ value: Double) throws {
            
            try write(box(value))
        }
        
        public func encode<T : Swift.Encodable>(_ value: T) throws {
            
            try value.encode(to: encoder)
        }
        
        private func write(_ value: NSObject?) throws {
            
            guard let codingKey = self.codingPath.last else {
                
                let context = EncodingError.Context(codingPath: codingPath,
                                                    debugDescription: "No key was provided for single value container.",
                                                    underlyingError: CoreDataEncoder.Error.noKey)
                
                let error = EncodingError.invalidValue(value as Any, context)
                
                throw error
            }
            
            // set value
            try encoder.set(value, forKey: codingKey)
        }
    }
}

// MARK: - UnkeyedEncodingContainer

fileprivate extension CoreDataEncoder.Encoder {
    
    fileprivate struct UnkeyedEncodingContainer: Swift.UnkeyedEncodingContainer {
        
        fileprivate let encoder: CoreDataEncoder.Encoder
        
        /// A reference to the container we're writing to.
        private var container: NSManagedObject {
            
            get { return encoder.managedObject }
        }
        
        var codingPath: [CodingKey] {
            
            get { return encoder.codingPath }
        }
        
        var count: Int { return (try? collection().count) ?? 0 }
        
        mutating func encodeNil() throws {
            
            // do nothing
            // FIXME: Add option to throw error
        }
        
        mutating func encode(_ value: Bool) throws {
            
            throw invalidTypeError(for: value)
        }
        
        mutating func encode(_ value: Int) throws {
            
            throw invalidTypeError(for: value)
        }
        
        mutating func encode(_ value: Int8) throws {
            
            throw invalidTypeError(for: value)
        }
        
        mutating func encode(_ value: Int16) throws {
            
            throw invalidTypeError(for: value)
        }
        
        mutating func encode(_ value: Int32) throws {
            
            throw invalidTypeError(for: value)
        }
        
        mutating func encode(_ value: Int64) throws {
            
            throw invalidTypeError(for: value)
        }
        
        mutating func encode(_ value: UInt) throws {
            
            throw invalidTypeError(for: value)
        }
        
        mutating func encode(_ value: UInt8) throws {
            
            throw invalidTypeError(for: value)
        }
        
        mutating func encode(_ value: UInt16) throws {
            
            throw invalidTypeError(for: value)
        }
        
        mutating func encode(_ value: UInt32) throws {
            
            throw invalidTypeError(for: value)
        }
        
        mutating func encode(_ value: UInt64) throws {
            
            throw invalidTypeError(for: value)
        }
        
        mutating func encode(_ value: Float) throws {
            
            throw invalidTypeError(for: value)
        }
        
        mutating func encode(_ value: Double) throws {
            
            throw invalidTypeError(for: value)
        }
        
        mutating func encode(_ value: String) throws {
            
            throw invalidTypeError(for: value)
        }
        
        mutating func encode<T>(_ value: T) throws where T : Swift.Encodable {
            
            if let identifier = value as? CoreDataIdentifier {
                
                let managedObject = try identifier.findOrCreate(in: encoder.managedObjectContext)
                
                try write(managedObject)
                
            } else {
                
                throw invalidTypeError(for: value)
            }
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> Swift.KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            
            fatalError()
        }
        
        mutating func nestedUnkeyedContainer() -> Swift.UnkeyedEncodingContainer {
            fatalError()
        }
        
        mutating func superEncoder() -> Swift.Encoder {
            
            return encoder
        }
        
        private func codingKey() throws -> CodingKey {
            
            guard let codingKey = self.codingPath.last
                else { throw CoreDataEncoder.Error.noKey }
            
            return codingKey
        }
        
        /// Get array of to-many relationship
        private func collection() throws -> [NSManagedObject] {
            
            let key = try codingKey()
            
            if let value = container.value(forKey: key.stringValue) as! NSObject? {
                
                if let set = value as? Set<NSManagedObject> {
                    
                    return Array(set)
                    
                } else if let orderedSet = value as? NSOrderedSet {
                    
                    return orderedSet.array as! [NSManagedObject]
                    
                } else {
                    
                    throw CoreDataEncoder.Error.invalidType
                }
                
            } else {
                
                return []
            }
        }
        
        private func write(_ managedObject: NSManagedObject) throws {
            
            let key = try codingKey()
            
            var managedObjects = try collection()
            
            managedObjects.append(managedObject)
            
            let set = NSSet(array: managedObjects)
            
            // set value
            try encoder.set(set, forKey: key)
        }
        
        private func invalidTypeError(for value: Any) -> Error {
            
            let context = EncodingError.Context(codingPath: codingPath,
                                                debugDescription: "The expected value should be a relationship.",
                                                underlyingError: CoreDataEncoder.Error.invalidType)
            
            let error = EncodingError.invalidValue(value, context)
            
            return error
        }
    }
}
