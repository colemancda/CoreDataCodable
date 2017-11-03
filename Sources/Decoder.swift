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
                              decodable: decodable,
                              userInfo: userInfo,
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
    
    fileprivate class Decoder <Decodable: CoreDataCodable> : Swift.Decoder {
        
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
        
        // MARK: - Initialization
        
        fileprivate init(managedObjectContext: NSManagedObjectContext,
                         managedObject: NSManagedObject,
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
        
        func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
            
            
        }
        
        func unkeyedContainer() throws -> UnkeyedDecodingContainer {
            
            
        }
        
        func singleValueContainer() throws -> SingleValueDecodingContainer {
            
            
        }
    }
}

