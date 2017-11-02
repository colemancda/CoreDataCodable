//
//  CoreDataCodable.swift
//  ColemanCDA
//
//  Created by Alsey Coleman Miller on 11/1/17.
//  Copyright © 2017 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

public final class CoreDataEncoder: Encoder {
    
    // MARK: - Properties
    
    /// The managed object used to encode values.
    public let managedObjectContext: NSManagedObjectContext
    
    /// The path of coding keys taken to get to this point in encoding.
    public private(set) var codingPath = [CodingKey]()
    
    /// Any contextual information set by the user for encoding.
    public var userInfo = [CodingUserInfoKey : Any]()
    
    /// The current managed object being encoded.
    private var managedObject: NSManagedObject?
    
    // MARK: - Initialization
    
    public init(managedObjectContext: NSManagedObjectContext) {
        
        self.managedObjectContext = managedObjectContext
    }
    
    // MARK: - Methods
    
    public func encode<Encodable : CoreDataEncodable>(_ encodable: Encodable) throws -> Encodable.ManagedObject {
        
        // get managed object
        let managedObject = encodable.findOrCreate(in: managedObjectContext)
        self.managedObject = managedObject
        defer { self.managedObject = nil }
        
        // will throw if the encoder doesnt have any managed object
        try encodable.encode(to: self)
        
        
    }
    
    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        
        if let managedObject = self.managedObject {
            
            let container = ManagedObjectKeyedEncodingContainer<Key>(referencing: self,
                                                                     codingPath: codingPath,
                                                                     wrapping: managedObject)
            
            return KeyedEncodingContainer<Key>(container)
            
        } else {
            
            let container = InvalidKeyedEncodingContainer<Key>(referencing: self,
                                                               codingPath: codingPath,
                                                               underlyingError: .noManagedObject)
            
            return KeyedEncodingContainer<Key>(container)
        }
    }
    
    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        
        fatalError()
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        
        fatalError()
    }
    
    
}

private final class _CoreDataEncoder: Encodable {
    
    
}

// MARK: - Supporting Types

public extension CoreDataEncoder {
    
    public enum Error: Swift.Error {
        
        /// The managed object is missing from the context.
        /// Most likely this is due to using the encoding a type that does not conform to `CoreDataEncodable`.
        case noManagedObject
    }
}

public typealias CoreDataCodable = CoreDataEncodable // & CoreDataDecodable

/// Specifies how a type can be encoded to be stored with Core Data.
public protocol CoreDataEncodable: Encodable {
    
    associatedtype ManagedObject: NSManagedObject
    
    /// Find or create
    func findOrCreate(in context: NSManagedObjectContext) -> ManagedObject
}

public protocol CoreDataIdentifier: RawRepresentable, Codable {
    
    associatedtype CoreData: CoreDataCodable
}

// MARK: - KeyedEncodingContainer

private extension CoreDataEncoder {
    
    /// Fake container for invalid encoder context.
    private struct InvalidKeyedEncodingContainer<K : CodingKey> : KeyedEncodingContainerProtocol {
        
        /// A reference to the encoder we're writing to.
        private let encoder: CoreDataEncoder
        
        private let underlyingError: CoreDataEncoder.Error
        
        public private(set) var codingPath: [CodingKey]
        
        init(referencing encoder: CoreDataEncoder, codingPath: [CodingKey], underlyingError: CoreDataEncoder.Error) {
            
            self.encoder = encoder
            self.codingPath = codingPath
            self.underlyingError = underlyingError
        }
        
        private mutating func encodingError(_ value: Any, for key: Key) -> Swift.Error {
            
            // set coding key context
            codingPath.append(key)
            defer { codingPath.removeLast() }
            
            let context = EncodingError.Context(codingPath: encoder.codingPath,
                                                debugDescription: "Cannot encode due to invalid context",
                                                underlyingError: underlyingError)
            
            let error = EncodingError.invalidValue(value, context)
            
            return error
        }
        
        public mutating func encodeNil(forKey key: Key)               throws { throw encodingError(NSNull(), for: key) }
        public mutating func encode(_ value: Bool, forKey key: Key)   throws { throw encodingError(value, for: key)  }
        public mutating func encode(_ value: Int, forKey key: Key)    throws { throw encodingError(value, for: key)  }
        public mutating func encode(_ value: Int8, forKey key: Key)   throws { throw encodingError(value, for: key)  }
        public mutating func encode(_ value: Int16, forKey key: Key)  throws { throw encodingError(value, for: key)  }
        public mutating func encode(_ value: Int32, forKey key: Key)  throws { throw encodingError(value, for: key)  }
        public mutating func encode(_ value: Int64, forKey key: Key)  throws { throw encodingError(value, for: key)  }
        public mutating func encode(_ value: UInt, forKey key: Key)   throws { throw encodingError(value, for: key)  }
        public mutating func encode(_ value: UInt8, forKey key: Key)  throws { throw encodingError(value, for: key)  }
        public mutating func encode(_ value: UInt16, forKey key: Key) throws { throw encodingError(value, for: key)  }
        public mutating func encode(_ value: UInt32, forKey key: Key) throws { throw encodingError(value, for: key)  }
        public mutating func encode(_ value: UInt64, forKey key: Key) throws { throw encodingError(value, for: key)  }
        public mutating func encode(_ value: String, forKey key: Key) throws { throw encodingError(value, for: key)  }
        public mutating func encode(_ value: Float, forKey key: Key) throws { throw encodingError(value, for: key)  }
        public mutating func encode(_ value: Double, forKey key: Key) throws { throw encodingError(value, for: key)  }
        public mutating func encode<T>(_ value: T, forKey key: K) throws where T : Encodable { throw encodingError(value, for: key)  }
        public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            
            fatalError()
        }
        
        public mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
            
            fatalError()
        }
        
        public mutating func superEncoder() -> Encoder {
            
            return encoder
        }
        
        public mutating func superEncoder(forKey key: K) -> Encoder {
            
            return encoder
        }
    }
    
    private struct ManagedObjectKeyedEncodingContainer<K : CodingKey> : KeyedEncodingContainerProtocol {
        
        public typealias Key = K
        
        /// A reference to the encoder we're writing to.
        private let encoder: CoreDataEncoder
        
        /// A reference to the container we're writing to.
        private let container: NSManagedObject
        
        public private(set) var codingPath: [CodingKey]
        
        /// Initializes `self` with the given references.
        fileprivate init(referencing encoder: CoreDataEncoder, codingPath: [CodingKey], wrapping container: NSManagedObject) {
            
            precondition(container == encoder.managedObject)
            
            self.encoder = encoder
            self.codingPath = codingPath
            self.container = container
        }
        
        private mutating func write(_ value: NSObject?, forKey key: Key) throws {
            
            // set coding key context
            codingPath.append(key)
            defer { codingPath.removeLast() }
            
            // FIXME: test for valid property type
            
            self.container.setValue(value, forKey: key.stringValue)
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
        public mutating func encode(_ value: UUID, forKey key: Key) throws { try write(encoder.box(value), forKey: key) }
        public mutating func encode(_ value: URL, forKey key: Key) throws { try write(encoder.box(value), forKey: key) }
        public mutating func encode(_ value: URL, forKey key: Key) throws { try write(encoder.box(value), forKey: key) }
        
        public mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
            
            // get value
            
            try write(encoder.box(value), forKey: key)
        }
        
        public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            
            fatalError()
        }
        
        public mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
            
            fatalError()
        }
        
        public mutating func superEncoder() -> Encoder {
            
            fatalError()
        }
        
        public mutating func superEncoder(forKey key: K) -> Encoder {
            
            fatalError()
        }
    }
}

// MARK: - Concrete Value Representations

private extension CoreDataEncoder {
    
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
}

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

extension _CoreDataEncoder : SingleValueEncodingContainer {
    
    private func managedObject
    
    public func encodeNil() throws {
        
        self.storage.push(container: NSNull())
    }
    
    public func encode(_ value: Bool) throws {
        
        self.storage.push(container: self.box(value))
    }
    
    public func encode(_ value: Int) throws {
        
        self.storage.push(container: self.box(value))
    }
    
    public func encode(_ value: Int8) throws {
        
        self.storage.push(container: self.box(value))
    }
    
    public func encode(_ value: Int16) throws {
        
        self.storage.push(container: self.box(value))
    }
    
    public func encode(_ value: Int32) throws {
        
        self.storage.push(container: self.box(value))
    }
    
    public func encode(_ value: Int64) throws {
        
        self.storage.push(container: self.box(value))
    }
    
    public func encode(_ value: UInt) throws {
        
        self.storage.push(container: self.box(value))
    }
    
    public func encode(_ value: UInt8) throws {
        
        self.storage.push(container: self.box(value))
    }
    
    public func encode(_ value: UInt16) throws {
        
        self.storage.push(container: self.box(value))
    }
    
    public func encode(_ value: UInt32) throws {
        
        self.storage.push(container: self.box(value))
    }
    
    public func encode(_ value: UInt64) throws {
        
        self.storage.push(container: self.box(value))
    }
    
    public func encode(_ value: String) throws {
        
        self.storage.push(container: self.box(value))
    }
    
    public func encode(_ value: Float) throws {
        
        try self.storage.push(container: self.box(value))
    }
    
    public func encode(_ value: Double) throws {
        
        try self.storage.push(container: self.box(value))
    }
    
    public func encode<T : Encodable>(_ value: T) throws {
        
        try self.storage.push(container: self.box(value))
    }
}
