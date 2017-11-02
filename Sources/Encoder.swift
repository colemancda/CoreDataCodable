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
    
    public func encode<Encodable : CoreDataCodable>(_ encodable: Encodable) throws -> Encodable.ManagedObject {
        
        return try encode(encodable, codingPath: [])
    }
    
    fileprivate func encode<Encodable : CoreDataCodable>(_ encodable: Encodable, codingPath: [CodingKey]) throws -> Encodable.ManagedObject {
        
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
        
        /// The managed object is missing from the context.
        /// Most likely this is due to using the encoding a type that does not conform to `CoreDataEncodable`.
        case noManagedObject
        
        /// No key for single value encoding. 
        case noKey
        
        case invalidSelector(Selector)
    }
    
    public typealias Log = (String) -> ()
}

// MARK: - Encodable

fileprivate extension CoreDataEncoder {
    
    fileprivate final class Encoder <Encodable: CoreDataCodable>: Swift.Encoder {
        
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
        public let encodable: Encodable
        
        /// Logger
        public let log: Log?
        
        // MARK: - Initialization
        
        fileprivate init(managedObjectContext: NSManagedObjectContext,
                         managedObject: NSManagedObject,
                         encodable: Encodable,
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
            
            let container = CoreDataEncoder.KeyedEncodingContainer<Key, Encodable>(encoder: self)
            
            return Swift.KeyedEncodingContainer<Key>(container)
        }
        
        public func unkeyedContainer() -> Swift.UnkeyedEncodingContainer {
            
            return UnkeyedEncodingContainer(encoder: self)
        }
        
        public func singleValueContainer() -> Swift.SingleValueEncodingContainer {
            
            //precondition(self.codingPath.last != nil)
            
            return SingleValueEncodingContainer(encoder: self)
        }
        
        fileprivate func set(_ value: NSObject?, forKey key: CodingKey) throws {
            
            // log
            log?("\(CoreDataEncoder.self): Will set \(value?.description ?? "nil") for key \(codingPath.reduce("", { $0 + "\($0.isEmpty ? "" : ".")" + $1.stringValue }))")
            
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
}

// MARK: - KeyedEncodingContainer

fileprivate extension CoreDataEncoder {
    
    fileprivate struct KeyedEncodingContainer<K : CodingKey, Encodable: CoreDataCodable> : KeyedEncodingContainerProtocol {
        
        public typealias Key = K
        
        /// A reference to the encoder we're writing to.
        fileprivate let encoder: CoreDataEncoder.Encoder<Encodable>
        
        /// A reference to the container we're writing to.
        private var container: NSManagedObject {
            
            get { return encoder.managedObject }
        }
        
        /// The path of coding keys taken to get to this point in encoding.
        public fileprivate(set) var codingPath: [CodingKey] {
            
            get { return encoder.codingPath }
            
            mutating set { encoder.codingPath = newValue }
        }
        
        private mutating func write(_ value: NSObject?, forKey key: Key) throws {
            
            // set coding key context
            codingPath.append(key)
            defer { codingPath.removeLast() }
            
            // set value
            try encoder.set(value, forKey: key)
        }
        
        public mutating func encodeNil(forKey key: Key)               throws { try write(nil, forKey: key) }
        public mutating func encode(_ value: Bool, forKey key: Key)   throws { try write(encoder.box(value), forKey: key) }
        public mutating func encode(_ value: Int, forKey key: Key)    throws { try write(encoder.box(value), forKey: key) }
        public mutating func encode(_ value: Int8, forKey key: Key)   throws { try write(encoder.box(value), forKey: key) }
        public mutating func encode(_ value: Int16, forKey key: Key)  throws { try write(encoder.box(value), forKey: key) }
        public mutating func encode(_ value: Int32, forKey key: Key)  throws { try write(encoder.box(value), forKey: key) }
        public mutating func encode(_ value: Int64, forKey key: Key)  throws { try write(encoder.box(value), forKey: key) }
        public mutating func encode(_ value: UInt, forKey key: Key)   throws { try write(encoder.box(value), forKey: key) }
        public mutating func encode(_ value: UInt8, forKey key: Key)  throws { try write(encoder.box(value), forKey: key) }
        public mutating func encode(_ value: UInt16, forKey key: Key) throws { try write(encoder.box(value), forKey: key) }
        public mutating func encode(_ value: UInt32, forKey key: Key) throws { try write(encoder.box(value), forKey: key) }
        public mutating func encode(_ value: UInt64, forKey key: Key) throws { try write(encoder.box(value), forKey: key) }
        public mutating func encode(_ value: String, forKey key: Key) throws { try write(encoder.box(value), forKey: key) }
        public mutating func encode(_ value: Float, forKey key: Key) throws { try write(encoder.box(value), forKey: key) }
        public mutating func encode(_ value: Double, forKey key: Key) throws { try write(encoder.box(value), forKey: key) }
        
        // Custom
        public mutating func encode(_ value: Data, forKey key: Key) throws { try write(encoder.box(value), forKey: key) }
        public mutating func encode(_ value: Date, forKey key: Key) throws { try write(encoder.box(value), forKey: key) }
        public mutating func encode(_ value: UUID, forKey key: Key) throws { try write(encoder.box(value), forKey: key) }
        public mutating func encode(_ value: URL, forKey key: Key) throws { try write(encoder.box(value), forKey: key) }
        public mutating func encode(_ value: Decimal, forKey key: Key) throws { try write(encoder.box(value), forKey: key) }
        
        public mutating func encode<Identifier: CoreDataIdentifier>(_ value: Identifier, forKey key: Key) throws {
            
            
        }
        
        public mutating func encode<T: Swift.Encodable>(_ value: T, forKey key: Key) throws {
            
            // override for CoreData supported native types that also are Encodable
            // and don't use encodable implementation
            
            if let value = value as? Data {
                
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
    }
}

fileprivate extension CoreDataEncoder.Encoder {
    
    fileprivate struct SingleValueEncodingContainer<Encodable: CoreDataCodable>: Swift.SingleValueEncodingContainer {
        
        fileprivate let encoder: CoreDataEncoder.Encoder<Encodable>
        
        /// A reference to the container we're writing to.
        private var container: NSManagedObject {
            
            get { return encoder.managedObject }
        }
        
        public var codingPath: [CodingKey] {
            
            get { return encoder.codingPath }
        }
        
        @inline(__always)
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
        
        public func encodeNil() throws {
            
            try write(nil)
        }
        
        public func encode(_ value: Bool) throws {
            
            try write(encoder.box(value))
        }
        
        public func encode(_ value: Int) throws {
            
            try write(encoder.box(value))
        }
        
        public func encode(_ value: Int8) throws {
            
            try write(encoder.box(value))
        }
        
        public func encode(_ value: Int16) throws {
            
            try write(encoder.box(value))
        }
        
        public func encode(_ value: Int32) throws {
            
            try write(encoder.box(value))
        }
        
        public func encode(_ value: Int64) throws {
            
            try write(encoder.box(value))
        }
        
        public func encode(_ value: UInt) throws {
            
            try write(encoder.box(value))
        }
        
        public func encode(_ value: UInt8) throws {
            
            try write(encoder.box(value))
        }
        
        public func encode(_ value: UInt16) throws {
            
            try write(encoder.box(value))
        }
        
        public func encode(_ value: UInt32) throws {
            
            try write(encoder.box(value))
        }
        
        public func encode(_ value: UInt64) throws {
            
            try write(encoder.box(value))
        }
        
        public func encode(_ value: String) throws {
            
            try write(encoder.box(value))
        }
        
        public func encode(_ value: Float) throws {
            
            try write(encoder.box(value))
        }
        
        public func encode(_ value: Double) throws {
            
            try write(encoder.box(value))
        }
        
        public func encode<T : Swift.Encodable>(_ value: T) throws {
            
            try value.encode(to: encoder)
        }
    }
}

fileprivate extension CoreDataEncoder.Encoder {
    
    fileprivate struct UnkeyedEncodingContainer<Encodable: CoreDataCodable>: Swift.UnkeyedEncodingContainer {
        
        fileprivate let encoder: CoreDataEncoder.Encoder<Encodable>
        
        var codingPath: [CodingKey] { return [] }
        
        var count: Int { return 0 }
        
        mutating func encodeNil() throws {
            
            
        }
        
        mutating func encode(_ value: Bool) throws {
            
            
        }
        
        mutating func encode(_ value: Int) throws {
            
        }
        
        mutating func encode(_ value: Int8) throws {
            
        }
        
        mutating func encode(_ value: Int16) throws {
            
        }
        
        mutating func encode(_ value: Int32) throws {
            
        }
        
        mutating func encode(_ value: Int64) throws {
            
        }
        
        mutating func encode(_ value: UInt) throws {
            
        }
        
        mutating func encode(_ value: UInt8) throws {
            
        }
        
        mutating func encode(_ value: UInt16) throws {
            
        }
        
        mutating func encode(_ value: UInt32) throws {
            
        }
        
        mutating func encode(_ value: UInt64) throws {
            
        }
        
        mutating func encode(_ value: Float) throws {
            
        }
        
        mutating func encode(_ value: Double) throws {
            
        }
        
        mutating func encode(_ value: String) throws {
            
        }
        
        mutating func encode<T>(_ value: T) throws where T : Swift.Encodable {
            
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> Swift.KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            
            fatalError()
        }
        
        mutating func nestedUnkeyedContainer() -> Swift.UnkeyedEncodingContainer {
            fatalError()
        }
        
        mutating func superEncoder() -> Swift.Encoder {
            fatalError()
        }
    }
}

// MARK: - Concrete Value Representations

private extension CoreDataEncoder.Encoder {
    
    // Returns the given value boxed in a container appropriate for pushing onto the container stack.
    
    func box(_ value: Bool)   -> NSObject { return NSNumber(value: value) }
    func box(_ value: Int)    -> NSObject { return NSNumber(value: value) }
    func box(_ value: Int8)   -> NSObject { return NSNumber(value: value) }
    func box(_ value: Int16)  -> NSObject { return NSNumber(value: value) }
    func box(_ value: Int32)  -> NSObject { return NSNumber(value: value) }
    func box(_ value: Int64)  -> NSObject { return NSNumber(value: value) }
    func box(_ value: UInt)   -> NSObject { return NSNumber(value: value) }
    func box(_ value: UInt8)  -> NSObject { return NSNumber(value: value) }
    func box(_ value: UInt16) -> NSObject { return NSNumber(value: value) }
    func box(_ value: UInt32) -> NSObject { return NSNumber(value: value) }
    func box(_ value: UInt64) -> NSObject { return NSNumber(value: value) }
    func box(_ value: Float) -> NSObject { return NSNumber(value: value) }
    func box(_ value: Double) -> NSObject { return NSNumber(value: value) }
    func box(_ value: String) -> NSObject { return NSString(string: value) }
    func box(_ date: Date) -> NSObject { return date as NSDate }
    func box(_ data: Data) -> NSObject { return data as NSData }
    func box(_ uuid: UUID) -> NSObject { return uuid as NSUUID }
    func box(_ url: URL) -> NSObject { return url as NSURL }
    func box(_ decimal: Decimal) -> NSObject { return decimal as NSDecimalNumber }
}
/*
fileprivate struct _CoreDataKeyedEncodingContainer<K : CodingKey> : KeyedEncodingContainerProtocol {
    typealias Key = K
    
    // MARK: Properties
    
    /// A reference to the encoder we're writing to.
    private let encoder: _CoreDataEncoder
    
    /// A reference to the container we're writing to.
    private let container: NSManagedObject
    
    /// The path of coding keys taken to get to this point in encoding.
    private(set) public var codingPath: [CodingKey]
    
    // MARK: - Initialization
    
    /// Initializes `self` with the given references.
    fileprivate init(referencing encoder: _CoreDataEncoder, codingPath: [CodingKey], wrapping container: NSManagedObject) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.container = container
    }
    
    // MARK: - Methods
    
    private func write(_ value: NSObject?, forKey key: Key) throws {
        
        // FIXME: test for valid property type
        
        self.container.setValue(value, forKey: key.stringValue)
        
        
    }
    
    // MARK: - KeyedEncodingContainerProtocol Methods
    
    public mutating func encodeNil(forKey key: Key)               throws { try write(nil, forKey: key) }
    public mutating func encode(_ value: Bool, forKey key: Key)   throws { try write(encoder.box(value), forKey: key) }
    public mutating func encode(_ value: Int, forKey key: Key)    throws { try write(encoder.box(value), forKey: key) }
    public mutating func encode(_ value: Int8, forKey key: Key)   throws { try write(encoder.box(value), forKey: key) }
    public mutating func encode(_ value: Int16, forKey key: Key)  throws { try write(encoder.box(value), forKey: key) }
    public mutating func encode(_ value: Int32, forKey key: Key)  throws { try write(encoder.box(value), forKey: key) }
    public mutating func encode(_ value: Int64, forKey key: Key)  throws { try write(encoder.box(value), forKey: key) }
    public mutating func encode(_ value: UInt, forKey key: Key)   throws { try write(encoder.box(value), forKey: key) }
    public mutating func encode(_ value: UInt8, forKey key: Key)  throws { try write(encoder.box(value), forKey: key) }
    public mutating func encode(_ value: UInt16, forKey key: Key) throws { try write(encoder.box(value), forKey: key) }
    public mutating func encode(_ value: UInt32, forKey key: Key) throws { try write(encoder.box(value), forKey: key) }
    public mutating func encode(_ value: UInt64, forKey key: Key) throws { try write(encoder.box(value), forKey: key) }
    public mutating func encode(_ value: String, forKey key: Key) throws { try write(encoder.box(value), forKey: key) }
    
    public mutating func encode(_ value: Float, forKey key: Key)  throws {
        // Since the float may be invalid and throw, the coding path needs to contain this key.
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        self.container[key.stringValue] = try self.encoder.box(value)
    }
    
    public mutating func encode(_ value: Double, forKey key: Key) throws {
        // Since the double may be invalid and throw, the coding path needs to contain this key.
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        self.container[key.stringValue] = try self.encoder.box(value)
    }
    
    public mutating func encode<T : Encodable>(_ value: T, forKey key: Key) throws {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        self.container[key.stringValue] = try self.encoder.box(value)
    }
    
    public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        let dictionary = NSMutableDictionary()
        self.container[key.stringValue] = dictionary
        
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        let container = _JSONKeyedEncodingContainer<NestedKey>(referencing: self.encoder, codingPath: self.codingPath, wrapping: dictionary)
        return KeyedEncodingContainer(container)
    }
    
    public mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let array = NSMutableArray()
        self.container[key.stringValue] = array
        
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        return _JSONUnkeyedEncodingContainer(referencing: self.encoder, codingPath: self.codingPath, wrapping: array)
    }
    
    public mutating func superEncoder() -> Encoder {
        return _JSONReferencingEncoder(referencing: self.encoder, at: _JSONKey.super, wrapping: self.container)
    }
    
    public mutating func superEncoder(forKey key: Key) -> Encoder {
        return _JSONReferencingEncoder(referencing: self.encoder, at: key, wrapping: self.container)
    }
}

*/
