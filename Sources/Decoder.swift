//
//  Decoder.swift
//  CoreDataCodable
//
//  Created by Alsey Coleman Miller on 11/3/17.
//  Copyright © 2017 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

public struct CoreDataDecoder {

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
    
    public func decode<Decodable: CoreDataCodable>(_ decodable: Decodable.Type, with identifier: CoreDataIdentifier) throws -> Decodable {
        
        // get managed object
        let managedObject = try identifier.findOrCreate(in: managedObjectContext)
        guard let decodableManagedObject = managedObject as? NSManagedObject & DecodableManagedObject else {
            
            let type = DecodableManagedObject.self
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: [], debugDescription: "Cannot decode \(type) from managed object \(managedObject.objectID.uriRepresentation()). Please conform to \(DecodableManagedObject.self)"))
        }
        
        // decode
        return try decode(decodable, from: decodableManagedObject)
    }
    
    public func decode<Decodable: CoreDataCodable>(_ decodable: Decodable.Type, from managedObject: NSManagedObject & DecodableManagedObject) throws -> Decodable {
        
        // create encoder for managed object
        let decoder = Decoder(managedObjectContext: managedObjectContext,
                              managedObject: managedObject,
                              codingPath: [],
                              userInfo: userInfo,
                              log: log)
        
        // decode from container
        return try Decodable.init(from: decoder)
    }
}

// MARK: - Supporting Types

public extension CoreDataDecoder {
    
    public enum Error: Swift.Error {
        
        public typealias Context = DecodingError.Context
        
        /// No key specified for container.
        case noKey(Context)
        
        /// Invalid selector (property doesn't exist)
        case invalidSelector(Selector, Context)
    }
    
    public typealias Log = (String) -> ()
}

// MARK: - Encoder

fileprivate extension CoreDataDecoder {
    
    fileprivate final class Decoder: Swift.Decoder {
        
        // MARK: - Properties
        
        /// The managed object used to decode values.
        public let managedObjectContext: NSManagedObjectContext
        
        /// The current managed object being decoded.
        public let managedObject: NSManagedObject & DecodableManagedObject
        
        /// The path of coding keys taken to get to this point in decoding.
        public fileprivate(set) var codingPath: [CodingKey]
        
        /// Any contextual information set by the user for decoding.
        public let userInfo: [CodingUserInfoKey : Any]
        
        /// Logger
        public let log: Log?
        
        /// Cached keys
        fileprivate lazy var allKeys: [String] = self.managedObject.entity.allKeys
        
        // MARK: - Initialization
        
        fileprivate init(managedObjectContext: NSManagedObjectContext,
                         managedObject: NSManagedObject & DecodableManagedObject,
                         codingPath: [CodingKey],
                         userInfo: [CodingUserInfoKey : Any],
                         log: Log?) {
            
            self.managedObjectContext = managedObjectContext
            self.managedObject = managedObject
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.log = log
        }
        
        // MARK: - Methods
        
        func container<Key>(keyedBy type: Key.Type) throws -> Swift.KeyedDecodingContainer<Key> where Key : CodingKey {
            
            log?("Requested container keyed by \(type) for path \"\(codingPathString)\"")
            
            let container = CoreDataDecoder.KeyedDecodingContainer<Key>(decoder: self)
            
            return Swift.KeyedDecodingContainer<Key>(container)
        }
        
        func unkeyedContainer() throws -> Swift.UnkeyedDecodingContainer {
            
            log?("Requested unkeyed container for path \"\(codingPathString)\"")
            
            // crash on debug builds
            assert(self.codingPath.last != nil)
            
            // throw if no key specified
            guard let key = self.codingPath.last else {
                
                throw CoreDataDecoder.Error.noKey(DecodingError.Context(codingPath: codingPath, debugDescription: "No key specified for unkeyed container."))
            }
            
            // get container for relationship
            let managedObjects = try read(Set<NSManagedObject>.self, for: key)
            
            guard let decodables = Array(managedObjects) as? [NSManagedObject & DecodableManagedObject] else {
                
                let type = [NSManagedObject & DecodableManagedObject].self
                
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode \(type) from managed object \(managedObject.objectID.uriRepresentation()). Please conform to \(DecodableManagedObject.self)"))
            }
            
            return UnkeyedDecodingContainer(decoder: self, container: decodables)
        }
        
        func singleValueContainer() throws -> Swift.SingleValueDecodingContainer {
            
            log?("Requested single value container for path \"\(codingPathString)\"")
            
            // crash on debug builds
            assert(self.codingPath.last != nil)
            
            // throw if no key specified
            guard let key = self.codingPath.last else {
                
                throw CoreDataDecoder.Error.noKey(DecodingError.Context(codingPath: codingPath, debugDescription: "No key specified for single value container."))
            }
            
            return SingleValueDecodingContainer(decoder: self, key: key)
        }
    }
}

fileprivate extension CoreDataDecoder.Decoder {
    
    var codingPathString: String {
        
        return codingPath.reduce("", { $0 + "\($0.isEmpty ? "" : ".")" + $1.stringValue })
    }
    
    /// Access actual value
    func value(for key: CodingKey) throws -> Any? {
        
        // log
        log?("Will read value for key \(key.stringValue) at path \"\(codingPathString)\"")
        
        // check schema / model contains property
        guard allKeys.contains(key.stringValue) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "No value associated with key \(key.stringValue)."))
        }
        
        // get value
        return managedObject.value(forKey: key.stringValue)
    }
    
    /// Attempt to get non optional value and cast to expected type.
    func read <T> (_ type: T.Type, for key: CodingKey) throws -> T {
        
        // get value or throw if nil
        guard let value = try self.value(for: key) else {
            
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        // convert
        guard let expected = value as? T else {
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(T.self) value but found \(value) instead."))
        }
        
        // get value
        return expected
    }
}

// MARK: - KeyedDecodingContainer

fileprivate extension CoreDataDecoder {
    
    fileprivate struct KeyedDecodingContainer<K : Swift.CodingKey>: Swift.KeyedDecodingContainerProtocol {
        
        typealias Key = K
        
        /// A reference to the encoder we're reading from.
        fileprivate let decoder: CoreDataDecoder.Decoder
        
        /// A reference to the container we're writing to.
        private var container: NSManagedObject & DecodableManagedObject {
            
            @inline(__always)
            get { return decoder.managedObject }
        }
        
        public private(set) var codingPath: [CodingKey] {
            
            @inline(__always)
            get { return decoder.codingPath }
            
            @inline(__always)
            nonmutating set { decoder.codingPath = newValue }
        }
        
         var allKeys: [Key] {
            
            return decoder.allKeys.flatMap { Key(stringValue: $0) }
        }
        
        func contains(_ key: Key) -> Bool {
            
            // check schema / model contains property
            guard allKeys.contains(where: { $0.stringValue == key.stringValue })
                else { return false }
            
            return container.value(forKey: key.stringValue) != nil
        }
        
        func decodeNil(forKey key: Key) throws -> Bool {
            
            // set coding key context
            self.codingPath.append(key)
            defer { self.codingPath.removeLast() }
            
            return try decoder.value(for: key) == nil
        }
        
        // Standard primitive types
        func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool { return try read(type, for: key) }
        func decode(_ type: Int.Type, forKey key: Key) throws -> Int { return try read(type, for: key) }
        func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 { return try read(type, for: key) }
        func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 { return try read(type, for: key) }
        func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 { return try read(type, for: key) }
        func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 { return try read(type, for: key) }
        func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt { return try read(type, for: key) }
        func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 { return try read(type, for: key) }
        func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { return try read(type, for: key) }
        func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { return try read(type, for: key) }
        func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { return try read(type, for: key) }
        func decode(_ type: Float.Type, forKey key: Key) throws -> Float { return try read(type, for: key) }
        func decode(_ type: Double.Type, forKey key: Key) throws -> Double { return try read(type, for: key) }
        func decode(_ type: String.Type, forKey key: Key) throws -> String { return try read(type, for: key) }
        
        // Decodable
        func decode <T : Decodable> (_ type: T.Type, forKey key: Key) throws -> T {
            
            // override for CoreData supported native types that also are Decodable
            // and don't use Decodable implementation
            
            // identifier or to-one relationship
            if let identifierType = type as? CoreDataIdentifier.Type {
                
                let decodable = container.decodable
                
                let identifierKey = decodable.identifierKey
                
                // identifier
                if key.stringValue == identifierKey {
                    
                    return try identifier(identifierType, from: container, for: key) as! T
                    
                } else {
                    
                    // set relationship value
                    return try relationship(identifierType, for: key) as! T
                }
                
            } else if let type = type as? Data.Type {
                
                return try read(T.self, for: key)
                
            } else if let type = type as? Date.Type {
                
                return try read(T.self, for: key)
                
            } else if let type = type as? UUID.Type {
                
                return try read(T.self, for: key)
                
            } else if let type = type as? URL.Type {
                
                return try read(T.self, for: key)
                
            } else if let type = type as? Decimal.Type {
                
                return try read(T.self, for: key)
                
            } else {
                
                // set coding key context
                codingPath.append(key)
                defer { codingPath.removeLast() }
                
                // get value
                return try T.init(from: decoder)
            }
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> Swift.KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            
            fatalError()
        }
        
        func nestedUnkeyedContainer(forKey key: Key) throws -> Swift.UnkeyedDecodingContainer {
            
            fatalError()
        }
        
        func superDecoder() throws -> Swift.Decoder {
            
            return decoder
        }
        
        func superDecoder(forKey key: Key) throws -> Swift.Decoder {
            
            return decoder
        }
        
        private func read <T> (_ type: T.Type, for key: Key) throws -> T {
            
            // set coding key context
            self.codingPath.append(key)
            defer { self.codingPath.removeLast() }
            
            // decode value for key
            return try decoder.read(type, for: key)
        }
        
        /// Get an identifier from a managed object
        private func identifier (_ type: CoreDataIdentifier.Type, from managedObject: NSManagedObject, for key: Key) throws -> CoreDataIdentifier {
            
            // create identifier from managed object
            guard let identifier = type.init(managedObject: managedObject) else {
                
                // set coding key context for error
                self.codingPath.append(key)
                defer { self.codingPath.removeLast() }
                
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Could not create identifier from managed object \(managedObject.objectID.uriRepresentation())."))
            }
            
            return identifier
        }
        
        /// attempt to read from to-one relationship
        private func relationship (_ type: CoreDataIdentifier.Type, for key: Key) throws -> CoreDataIdentifier {
            
            // get managed object
            let managedObject = try read(NSManagedObject.self, for: key)
            
            return try identifier(type, from: managedObject, for: key)
        }
        
        /// attempt to read from to-many relationship
        private func relationship (_ type: [CoreDataIdentifier].Type, for key: Key) throws -> [CoreDataIdentifier] {
            
            // get managed objects
            let managedObject = try read(Set<NSManagedObject>.self, for: key)
            
            // get identifiers from managed objects
            return try managedObject.map { try identifier(type.Element.self as! CoreDataIdentifier.Type, from: $0, for: key) }
        }
        
        private func relationship (_ type: CoreDataCodable.Type, for key: Key) throws -> CoreDataCodable {
            
            // get managed object
            //let managedObject = try read(NSManagedObject.self, for: key)
            
            fatalError()
        }
        
        private func relationship (_ type: [CoreDataCodable].Type, for key: Key) throws -> [CoreDataCodable] {
            
            // get managed objects
            //let managedObject = try read(Set<NSManagedObject>.self, for: key)
            
            fatalError()
        }
    }
}

// MARK: - SingleValueDecodingContainer

fileprivate extension CoreDataDecoder {
    
    fileprivate struct SingleValueDecodingContainer: Swift.SingleValueDecodingContainer {
        
        /// A reference to the encoder we're reading from.
        fileprivate let decoder: CoreDataDecoder.Decoder
        
        fileprivate let key: CodingKey
        
        /// A reference to the container we're reading from.
        private var container: NSManagedObject & DecodableManagedObject {
            
            @inline(__always)
            get { return decoder.managedObject }
        }
        
        public private(set) var codingPath: [CodingKey] {
            
            @inline(__always)
            get { return decoder.codingPath }
            
            @inline(__always)
            nonmutating set { decoder.codingPath = newValue }
        }
        
        func decodeNil() -> Bool {
            
            return (try? self.decoder.value(for: key)) == nil
        }
        
        func decode(_ type: Bool.Type) throws -> Bool { return try decoder.read(type, for: key) }
        func decode(_ type: Int.Type) throws -> Int { return try decoder.read(type, for: key) }
        func decode(_ type: Int8.Type) throws -> Int8 { return try decoder.read(type, for: key) }
        func decode(_ type: Int16.Type) throws -> Int16 { return try decoder.read(type, for: key) }
        func decode(_ type: Int32.Type) throws -> Int32 { return try decoder.read(type, for: key) }
        func decode(_ type: Int64.Type) throws -> Int64 { return try decoder.read(type, for: key) }
        func decode(_ type: UInt.Type) throws -> UInt { return try decoder.read(type, for: key) }
        func decode(_ type: UInt8.Type) throws -> UInt8 { return try decoder.read(type, for: key) }
        func decode(_ type: UInt16.Type) throws -> UInt16 { return try decoder.read(type, for: key) }
        func decode(_ type: UInt32.Type) throws -> UInt32 { return try decoder.read(type, for: key) }
        func decode(_ type: UInt64.Type) throws -> UInt64 { return try decoder.read(type, for: key) }
        func decode(_ type: Float.Type) throws -> Float { return try decoder.read(type, for: key) }
        func decode(_ type: Double.Type) throws -> Double { return try decoder.read(type, for: key) }
        func decode(_ type: String.Type) throws -> String { return try decoder.read(type, for: key) }
        
        func decode <T : Decodable> (_ type: T.Type) throws -> T {
            
            return try type.init(from: decoder)
        }
    }
}

fileprivate extension CoreDataDecoder {
    
    fileprivate struct UnkeyedDecodingContainer: Swift.UnkeyedDecodingContainer {
        
        /// A reference to the encoder we're reading from.
        fileprivate let decoder: CoreDataDecoder.Decoder
        
        /// A reference to the container we're reading from.
        fileprivate let container: [NSManagedObject & DecodableManagedObject]
        
        fileprivate init(decoder: CoreDataDecoder.Decoder, container: [NSManagedObject & DecodableManagedObject]) {
            
            self.decoder = decoder
            self.container = container
        }
        
        public private(set) var codingPath: [CodingKey] {
            
            @inline(__always)
            get { return decoder.codingPath }
            
            @inline(__always)
            mutating set { decoder.codingPath = newValue }
        }
        
        public var count: Int? {
            return _count
        }
        
        public var _count: Int {
            return container.count
        }
        
        public var isAtEnd: Bool {
            return currentIndex >= _count
        }
        
        public private(set) var currentIndex: Int = 0
        
        mutating func decodeNil() throws -> Bool {
            
            throw DecodingError.valueNotFound(Any?.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode nil from managed objects."))
        }
        
        mutating func decode(_ type: Bool.Type) throws -> Bool {
            
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode \(type) from managed objects."))
        }
        
        mutating func decode(_ type: Int.Type) throws -> Int { return try readIdentifier(type) }
        mutating func decode(_ type: Int8.Type) throws -> Int8 { return try readIdentifier(type) }
        mutating func decode(_ type: Int16.Type) throws -> Int16 { return try readIdentifier(type) }
        mutating func decode(_ type: Int32.Type) throws -> Int32 { return try readIdentifier(type) }
        mutating func decode(_ type: Int64.Type) throws -> Int64 { return try readIdentifier(type) }
        mutating func decode(_ type: UInt.Type) throws -> UInt { return try readIdentifier(type) }
        mutating func decode(_ type: UInt8.Type) throws -> UInt8 { return try readIdentifier(type) }
        mutating func decode(_ type: UInt16.Type) throws -> UInt16 { return try readIdentifier(type) }
        mutating func decode(_ type: UInt32.Type) throws -> UInt32 { return try readIdentifier(type) }
        mutating func decode(_ type: UInt64.Type) throws -> UInt64 { return try readIdentifier(type) }
        mutating func decode(_ type: Float.Type) throws -> Float { return try readIdentifier(type) }
        mutating func decode(_ type: Double.Type) throws -> Double { return try readIdentifier(type) }
        mutating func decode(_ type: String.Type) throws -> String { return try readIdentifier(type) }
        
        mutating func decode <T : Decodable> (_ type: T.Type) throws -> T {
            
            return try type.init(from: decoder)
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> Swift.KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode \(type) from managed objects."))
        }
        
        mutating func nestedUnkeyedContainer() throws -> Swift.UnkeyedDecodingContainer {
            
            throw DecodingError.typeMismatch([Any].self, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode unkeyed container from managed objects."))
        }
        
        mutating func superDecoder() throws -> Swift.Decoder {
            
            // set coding key context
            self.codingPath.append(Index(intValue: currentIndex))
            defer { self.codingPath.removeLast() }
            
            // log
            self.decoder.log?("Requested super decoder for path \"\(self.decoder.codingPathString)\"")
            
            // check for end of array
            guard isAtEnd == false else {
                
                throw DecodingError.valueNotFound(Decoder.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Unkeyed container is at end."))
            }
            
            // get stored managed object
            let managedObject = container[currentIndex]
            
            // increment counter
            self.currentIndex += 1
            
            let decoder = Decoder(managedObjectContext: self.decoder.managedObjectContext,
                                  managedObject: managedObject,
                                  codingPath: self.decoder.codingPath,
                                  userInfo: self.decoder.userInfo,
                                  log: self.decoder.log)
            
            return decoder
        }
        
        private mutating func readIdentifier <T> (_ type: T.Type) throws -> T {
            
            // set coding key context
            self.codingPath.append(Index(intValue: currentIndex))
            defer { self.codingPath.removeLast() }
            
            // check for end of array
            guard isAtEnd == false else {
                
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Unkeyed container is at end."))
            }
            
            // get stored managed object
            let managedObject = container[currentIndex]
            
            // decode value from managed object
            let identifier = managedObject.decodedIdentifier
            
            // try to get expected value type
            guard let expected = identifier as? T else {
                
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(T.self) value but found \(identifier) instead."))
            }
            
            // increment counter
            self.currentIndex += 1
            
            return expected
        }
    }
}

fileprivate extension CoreDataDecoder.UnkeyedDecodingContainer {
    
    struct Index: CodingKey {
        
        public let index: Int
        
        public init(intValue: Int) {
            
            self.index = intValue
        }
        
        init?(stringValue: String) {
            
            return nil
        }
        
        public var intValue: Int? {
            return index
        }
        
        public var stringValue: String {
            return "\(index)"
        }
    }
}
/*
fileprivate extension CoreDataDecoder.UnkeyedDecodingContainer {
    
    fileprivate final class Decoder: Swift.Decoder {
        
        // MARK: - Properties
        
        /// The decoder that created this decoder.
        public let parentDecoder: CoreDataDecoder.Decoder
        
        /// The managed object used to decode values.
        public let managedObjectContext: NSManagedObjectContext
        
        /// The current managed objects being decoded.
        public let managedObjects: [NSManagedObject & DecodableManagedObject]
        
        /// The path of coding keys taken to get to this point in decoding.
        public fileprivate(set) var codingPath: [CodingKey]
        
        /// Any contextual information set by the user for decoding.
        public let userInfo: [CodingUserInfoKey : Any]
        
        /// Logger
        public let log: CoreDataDecoder.Log?
        
        // MARK: - Initialization
        
        fileprivate init(parentDecoder: CoreDataDecoder.Decoder,
                         managedObjectContext: NSManagedObjectContext,
                         managedObjects: [NSManagedObject & DecodableManagedObject],
                         codingPath: [CodingKey],
                         userInfo: [CodingUserInfoKey : Any],
                         log: CoreDataDecoder.Log?) {
            
            self.managedObjectContext = managedObjectContext
            self.managedObjects = managedObjects
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.log = log
        }
        
        // MARK: - Methods
        
        func container<Key>(keyedBy type: Key.Type) throws -> Swift.KeyedDecodingContainer<Key> where Key : CodingKey {
            
            fatalError()
        }
        
        func unkeyedContainer() throws -> Swift.UnkeyedDecodingContainer {
            
            fatalError()
        }
        
        func singleValueContainer() throws -> Swift.SingleValueDecodingContainer {
            
            //log?("Requested single value container for path \"\(codingPathString)\"")
            
            // crash on debug builds
            assert(self.codingPath.last != nil)
            
            // throw if no key specified
            guard let key = self.codingPath.last else {
                
                throw CoreDataDecoder.Error.noKey(DecodingError.Context(codingPath: codingPath, debugDescription: "No key specified for single value container."))
            }
            
            if let index = key as? UnkeyedDecodingContainer.Index
            
            return SingleValueDecodingContainer(decoder: self, key: key)
        }
    }
}
*/
