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
        
        // create encoder for managed object
        let decoder = Decoder(managedObjectContext: managedObjectContext,
                              managedObject: managedObject,
                              codingPath: [],
                              userInfo: userInfo,
                              decodable: decodable,
                              log: log)
        
        // decode from container
        return try Decodable.init(from: decoder)
    }
}

// MARK: - Supporting Types

public extension CoreDataDecoder {
    
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

fileprivate extension CoreDataDecoder {
    
    fileprivate final class Decoder: Swift.Decoder {
        
        // MARK: - Properties
        
        /// The managed object used to decode values.
        public let managedObjectContext: NSManagedObjectContext
        
        /// The current managed object being decoded.
        public let managedObject: NSManagedObject
        
        /// The path of coding keys taken to get to this point in decoding.
        public fileprivate(set) var codingPath: [CodingKey]
        
        /// Any contextual information set by the user for decoding.
        public let userInfo: [CodingUserInfoKey : Any]
        
        /// Logger
        public let log: Log?
        
        public let decodable: CoreDataCodable.Type
        
        /// cached keys
        fileprivate lazy var allKeys: [String] = self.managedObject.entity.allKeys
        
        // MARK: - Initialization
        
        fileprivate init(managedObjectContext: NSManagedObjectContext,
                         managedObject: NSManagedObject,
                         codingPath: [CodingKey],
                         userInfo: [CodingUserInfoKey : Any],
                         decodable: CoreDataCodable.Type,
                         log: Log?) {
            
            self.managedObjectContext = managedObjectContext
            self.managedObject = managedObject
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.decodable = decodable
            self.log = log
        }
        
        // MARK: - Methods
        
        func container<Key>(keyedBy type: Key.Type) throws -> Swift.KeyedDecodingContainer<Key> where Key : CodingKey {
            
            
        }
        
        func unkeyedContainer() throws -> Swift.UnkeyedDecodingContainer {
            
            
        }
        
        func singleValueContainer() throws -> Swift.SingleValueDecodingContainer {
            
            
        }
        
        
    }
}

fileprivate extension CoreDataDecoder.Decoder {
    
    fileprivate func value(for key: CodingKey) throws -> Any? {
        
        // log
        log?("\(CoreDataEncoder.self): Will read value for key \"\(codingPath.reduce("", { $0 + "\($0.isEmpty ? "" : ".")" + $1.stringValue }))\"")
        
        // check schema / model contains property
        guard allKeys.contains(key.stringValue) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }
        
        // get value
        return managedObject.value(forKey: key.stringValue)
    }
}

// MARK: - KeyedDecodingContainer

fileprivate extension CoreDataDecoder {
    
    fileprivate struct KeyedDecodingContainer<K : Swift.CodingKey>: Swift.KeyedDecodingContainerProtocol {
        
        typealias Key = K
        
        fileprivate let decoder: CoreDataDecoder.Decoder
        
        /// A reference to the container we're writing to.
        private var container: NSManagedObject {
            
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
            
            return try self.decoder.value(for: key) == nil
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
                
                let decodable = decoder.decodable
                
                let identifierKey = decodable.identifierKey
                
                // identifier
                if key.stringValue == identifierKey {
                    
                    return try identifier(identifierType, from: container, for: key) as! T
                    
                } else {
                    
                    // set relationship value
                    return try relationship(identifierType, for: key) as! T
                }
                
            } else if let type = type as? CoreDataCodable.Type {
                
                return try relationship(type, for: key) as! T
                
            } else if let type = type as? [CoreDataIdentifier].Type {
                
                return try relationship(type, for: key) as! T
                
            } else if let type = type as? [CoreDataCodable].Type {
                
                return try relationship(type, for: key) as! T
                
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
            
            // get value or throw if nil
            guard let value = try self.decoder.value(for: key) else {
                
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(type) value but found null instead."))
            }
            
            // convert
            guard let expected = value as? T else {
                
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(type) value but found null instead."))
            }
            
            return expected
        }
        
        /// Get an identifier from a managed object
        private func identifier (_ type: CoreDataIdentifier.Type, from managedObject: NSManagedObject, for key: Key) throws -> CoreDataIdentifier {
            
            // get managed object
            let managedObject = try read(NSManagedObject.self, for: key)
            
            // create identifier from managed object
            guard let identifier = type.init(managedObject: managedObject) else {
                
                // set coding key context for error
                self.codingPath.append(key)
                defer { self.codingPath.removeLast() }
                
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Could not create identifier from managed object \(managedObject.objectID.uriRepresentation()) instead."))
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
            let managedObject = try read(NSManagedObject.self, for: key)
            
            
        }
        
        private func relationship (_ type: [CoreDataCodable].Type, for key: Key) throws -> [CoreDataCodable] {
            
            // get managed objects
            let managedObject = try read(Set<NSManagedObject>.self, for: key)
            
            
        }
    }
}
