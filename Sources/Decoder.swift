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
    
    public var options = Options()
    
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
        let decoder = Decoder(referencing: .managedObject(managedObject),
                              managedObjectContext: managedObjectContext,
                              userInfo: userInfo,
                              log: log,
                              options: options)
        
        // decode from container
        return try Decodable.init(from: decoder)
    }
}

// MARK: - Supporting Types

public extension CoreDataDecoder {
    
    public typealias Log = (String) -> ()
    
    public struct Options {
        
        public var nonNativeIntegerDecodingStrategy: NonNativeIntegerDecodingStrategy = .exactly
    }
    
    /// How to decode integers that arent supported by CoreData (e.g. Int8, UInt16).
    public enum NonNativeIntegerDecodingStrategy {
        
        /// Always throw for unsupported integer types.
        case `throw`
        
        /// Attempt to cast and throw if it cannot safely fit, use `init?(exactly number: NSNumber)`.
        case exactly
        
        /// Truncate number, use `init(truncating number: NSNumber)`.
        case truncating
    }
}

// MARK: - Decoder

fileprivate extension CoreDataDecoder {
    
    fileprivate final class Decoder: Swift.Decoder {
        
        // MARK: - Properties
        
        /// The managed object used to decode values.
        public let managedObjectContext: NSManagedObjectContext
        
        /// The current managed object being decoded.
        public var stack: Stack
        
        /// The path of coding keys taken to get to this point in decoding.
        public fileprivate(set) var codingPath: [CodingKey]
        
        /// Any contextual information set by the user for decoding.
        public let userInfo: [CodingUserInfoKey : Any]
        
        /// Logger
        public let log: Log?
        
        /// Decoding options.
        public let options: Options
        
        // MARK: - Initialization
        
        fileprivate init(referencing container: Stack.Container,
                         at codingPath: [CodingKey] = [],
                         managedObjectContext: NSManagedObjectContext,
                         userInfo: [CodingUserInfoKey : Any],
                         log: Log?,
                         options: Options) {
            
            self.stack = Stack(container: container)
            self.managedObjectContext = managedObjectContext
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.log = log
            self.options = options
        }
        
        // MARK: - Methods
        
        func container<Key: CodingKey>(keyedBy type: Key.Type) throws -> Swift.KeyedDecodingContainer<Key> {
            
            log?("Requested container keyed by \(type) for path \"\(codingPathString)\"")
            
            guard case let .managedObject(managedObject) = self.stack.top else {
                
                throw DecodingError.typeMismatch(KeyedDecodingContainer<Key>.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Cannot get keyed decoding container, invalid container type expected."))
            }
            
            let container = ManagedObjectKeyedDecodingContainer<Key>(referencing: self, wrapping: managedObject)
            
            return KeyedDecodingContainer(container)
        }
        
        func unkeyedContainer() throws -> Swift.UnkeyedDecodingContainer {
            
            log?("Requested unkeyed container for path \"\(codingPathString)\"")
            
            guard case let .relationship(managedObjects) = self.stack.top else {
                
                throw DecodingError.typeMismatch(UnkeyedDecodingContainer.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Cannot get unkeyed decoding container, invalid container type expected."))
            }
            
            
        }
        
        func singleValueContainer() throws -> Swift.SingleValueDecodingContainer {
            
            log?("Requested single value container for path \"\(codingPathString)\"")
            
            switch self.stack.top {
                
            // get single value container for attribute value
            case let .value(value):
                
                return AttributeSingleValueDecodingContainer(referencing: self, wrapping: value)
            
            // get single value container for to-one relationship managed object
            // decodes to CoreDataIdentifier
            case let .managedObject(managedObject):
                
                return RelationshipSingleValueDecodingContainer(referencing: self, wrapping: managedObject)
                
            case .relationship:
                
                throw DecodingError.typeMismatch(SingleValueDecodingContainer.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Cannot get single value decoding container, invalid container type expected."))
            }
        }
    }
}

// MARK: - Stack

fileprivate extension CoreDataDecoder {
    
    fileprivate struct Stack {
        
        enum Container {
            
            case managedObject(NSManagedObject)
            case relationship([NSManagedObject])
            case value(Any)
        }
        
        private(set) var containers = [Container]()
        
        fileprivate init(container: Container) {
            
            self.containers = [container]
        }
        
        var top: Container {
            
            guard let container = containers.last
                else { fatalError("Empty container stack.") }
            
            return container
        }
        
        mutating func push(_ container: Container) {
            
            containers.append(container)
        }
        
        @discardableResult
        mutating func pop() -> Container {
            
            guard let container = containers.popLast()
                else { fatalError("Empty container stack.") }
            
            return container
        }
    }
}

// MARK: - Unboxing Values

fileprivate extension CoreDataDecoder.Decoder {
    
    /// KVC path string for current coding path.
    var codingPathString: String {
        
        return codingPath.reduce("", { $0 + "\($0.isEmpty ? "" : ".")" + $1.stringValue })
    }
    
    /// Attempt to cast non optional native value to expected type.
    func unbox <T> (_ value: Any, as type: T.Type) throws -> T {
        
        // convert
        guard let expected = value as? T else {
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(T.self) value but found \(value) instead."))
        }
        
        // get value
        return expected
    }
    
    /// Attempt to decode native value to expected type.
    func unboxDecodable <T: Decodable> (_ value: Any, as type: T.Type) throws -> T {
        
        // override for CoreData supported native types that also are Decodable
        // and don't use Decodable implementation
        
        if type is Data.Type {
            
            return try unbox(value, as: type)
            
        } else if type is Date.Type {
            
            return try unbox(value, as: type)
            
        } else if type is UUID.Type {
            
            return try unbox(value, as: type)
            
        } else if type is URL.Type {
            
            return try unbox(value, as: type)
            
        } else if type is Decimal.Type {
            
            return (try unbox(value, as: NSDecimalNumber.self) as Decimal) as! T
            
        } else {
            
            let container: CoreDataDecoder.Stack.Container
            
            if let managedObject = value as? NSManagedObject {
                
                // Single value container for relationship
                container = .managedObject(managedObject)
                
            } else if let managedObjects = value as? Set<NSManagedObject> {
                
                // Unkeyed container for relationship
                container = .relationship(Array(managedObjects))
                
            } else if let orderedSet = value as? NSOrderedSet,
                let managedObjects = orderedSet.array as? [NSManagedObject] {
                
                // Unkeyed container for relationship
                container = .relationship(managedObjects)
                
            } else {
                
                /// single value container for attributes
                container = .value(value)
            }
            
            // push container to stack and decode using Decodable implementation
            stack.push(container)
            let decoded = try T(from: self)
            stack.pop()
            return decoded
        }
        
        // convert
        guard let expected = value as? T else {
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(T.self) value but found \(value) instead."))
        }
        
        // get value
        return expected
    }
    
    /// Attempt to convert non native numeric type to native type.
    func unbox(_ number: NSNumber) throws -> Int {
        
        let type = Int.self
        
        switch options.nonNativeIntegerDecodingStrategy {
            
        case .throw:
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(type) value but found \(number.objCType) instead."))
            
        case .exactly:
            
            guard let value = type.init(exactly: number) else {
                
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(type) value but found \(number.objCType) instead."))
            }
            
            return value
            
        case .truncating:
            
            return type.init(truncating: number)
        }
    }
    
    /// Attempt to convert non native numeric type to native type.
    func unbox(_ number: NSNumber) throws -> UInt {
        
        let type = UInt.self
        
        switch options.nonNativeIntegerDecodingStrategy {
            
        case .throw:
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(type) value but found \(number.objCType) instead."))
            
        case .exactly:
            
            guard let value = type.init(exactly: number) else {
                
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(type) value but found \(number.objCType) instead."))
            }
            
            return value
            
        case .truncating:
            
            return type.init(truncating: number)
        }
    }
    
    /// Attempt to convert non native numeric type to native type
    func unbox(_ number: NSNumber) throws -> Int8 {
        
        let type = Int8.self
        
        switch options.nonNativeIntegerDecodingStrategy {
            
        case .throw:
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(type) value but found \(number.objCType) instead."))
            
        case .exactly:
            
            guard let value = type.init(exactly: number) else {
                
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(type) value but found \(number.objCType) instead."))
            }
            
            return value
            
        case .truncating:
            
            return type.init(truncating: number)
        }
    }
    
    /// Attempt to convert non native numeric type to native type
    func unbox(_ number: NSNumber) throws -> UInt8 {
        
        let type = UInt8.self
        
        switch options.nonNativeIntegerDecodingStrategy {
            
        case .throw:
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(type) value but found \(number.objCType) instead."))
            
        case .exactly:
            
            guard let value = type.init(exactly: number) else {
                
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(type) value but found \(number.objCType) instead."))
            }
            
            return value
            
        case .truncating:
            
            return type.init(truncating: number)
        }
    }
    
    /// Attempt to convert non native numeric type to native type
    func unbox(_ number: NSNumber) throws -> UInt16 {
        
        let type = UInt16.self
        
        switch options.nonNativeIntegerDecodingStrategy {
            
        case .throw:
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(type) value but found \(number.objCType) instead."))
            
        case .exactly:
            
            guard let value = type.init(exactly: number) else {
                
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(type) value but found \(number.objCType) instead."))
            }
            
            return value
            
        case .truncating:
            
            return type.init(truncating: number)
        }
    }
    
    /// Attempt to convert non native numeric type to native type
    func unbox(_ number: NSNumber) throws -> UInt32 {
        
        let type = UInt32.self
        
        switch options.nonNativeIntegerDecodingStrategy {
            
        case .throw:
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(type) value but found \(number.objCType) instead."))
            
        case .exactly:
            
            guard let value = type.init(exactly: number) else {
                
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(type) value but found \(number.objCType) instead."))
            }
            
            return value
            
        case .truncating:
            
            return type.init(truncating: number)
        }
    }
    
    /// Attempt to convert non native numeric type to native type
    func unbox(_ number: NSNumber) throws -> UInt64 {
        
        let type = UInt64.self
        
        switch options.nonNativeIntegerDecodingStrategy {
            
        case .throw:
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(type) value but found \(number.objCType) instead."))
            
        case .exactly:
            
            guard let value = type.init(exactly: number) else {
                
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(type) value but found \(number.objCType) instead."))
            }
            
            return value
            
        case .truncating:
            
            return type.init(truncating: number)
        }
    }
}

// MARK: - KeyedDecodingContainer

fileprivate extension CoreDataDecoder {
    
    fileprivate struct ManagedObjectKeyedDecodingContainer<K : Swift.CodingKey>: Swift.KeyedDecodingContainerProtocol {
        
        typealias Key = K
        
        // MARK: Properties
        
        /// A reference to the encoder we're reading from.
        private let decoder: CoreDataDecoder.Decoder
        
        /// A reference to the container we're reading from.
        private let container: NSManagedObject
        
        /// The path of coding keys taken to get to this point in decoding.
        public let codingPath: [CodingKey]
        
        /// All the keys the Decoder has for this container.
        public let allKeys: [Key]
        
        // MARK: Initialization
        
        /// Initializes `self` by referencing the given decoder and container.
        fileprivate init(referencing decoder: CoreDataDecoder.Decoder, wrapping container: NSManagedObject) {
            
            self.decoder = decoder
            self.container = container
            self.codingPath = decoder.codingPath
            self.allKeys = container.entity.allKeys.flatMap { Key(stringValue: $0) }
        }
        
        // MARK: KeyedDecodingContainerProtocol
        
        func contains(_ key: Key) -> Bool {
            
            // log
            self.decoder.log?("Check whether key \"\(key.stringValue)\" exists")
            
            // check schema / model contains property
            guard allKeys.contains(where: { $0.stringValue == key.stringValue })
                else { return false }
            
            // return whether value exists for key
            return container.value(forKey: key.stringValue) != nil
        }
        
        func decodeNil(forKey key: Key) throws -> Bool {
            
            // set coding key context
            self.decoder.codingPath.append(key)
            defer { self.decoder.codingPath.removeLast() }
            
            return try self.value(for: key) == nil
        }
        
        func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
            
            return try _decode(type, forKey: key)
        }
        
        func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
            
            return try _decode(NSNumber.self, forKey: key) { try decoder.unbox($0) }
        }
        
        func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
            
            return try _decode(NSNumber.self, forKey: key) { try decoder.unbox($0) }
        }
        
        func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
            
            return try _decode(type, forKey: key)
        }
        
        func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
            
            return try _decode(type, forKey: key)
        }
        
        func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
            
            return try _decode(type, forKey: key)
        }
        
        func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
            
            return try _decode(NSNumber.self, forKey: key) { try decoder.unbox($0) }
        }
        
        func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
            
            return try _decode(NSNumber.self, forKey: key) { try decoder.unbox($0) }
        }
        
        func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
            
            return try _decode(NSNumber.self, forKey: key) { try decoder.unbox($0) }
        }
        
        func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
            
            return try _decode(NSNumber.self, forKey: key) { try decoder.unbox($0) }
        }
        
        func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
            
            return try _decode(NSNumber.self, forKey: key) { try decoder.unbox($0) }
        }
        
        func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
            
            return try _decode(type, forKey: key)
        }
        
        func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
            
            return try _decode(type, forKey: key)
        }
        
        func decode(_ type: String.Type, forKey key: Key) throws -> String {
            
            return try _decode(type, forKey: key)
        }
        
        func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
            
            self.decoder.codingPath.append(key)
            defer { self.decoder.codingPath.removeLast() }
            
            guard let entry = try self.value(for: key) else {
                
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
            }
            
            // override for CoreData supported native types that also are Decodable
            // and don't use Decodable implementation
            let value = try self.decoder.unboxDecodable(entry, as: type)
            
            return value
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            
            fatalError()
        }
        
        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            
            fatalError()
        }
        
        func superDecoder() throws -> Swift.Decoder {
            
            fatalError()
        }
        
        func superDecoder(forKey key: Key) throws -> Swift.Decoder {
            
            fatalError()
        }
        
        // MARK: Private Methods
        
        /// Decode native value type and map to
        private func _decode <T, Result> (_ type: T.Type, forKey key: Key, map: (T) throws -> (Result)) throws -> Result {
            
            self.decoder.codingPath.append(key)
            defer { self.decoder.codingPath.removeLast() }
            
            guard let entry = try self.value(for: key) else {
                
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
            }
            
            let value = try self.decoder.unbox(entry, as: type)
            
            return try map(value)
        }
        
        @inline(__always)
        private func _decode <T> (_ type: T.Type, forKey key: Key) throws -> T {
            
            return try _decode(type, forKey: key) { $0 }
        }
        
        /// Access actual value
        private func value(for key: Key) throws -> Any? {
            
            // log
            decoder.log?("Will read value for key \(key.stringValue) at path \"\(decoder.codingPathString)\"")
            
            // check schema / model contains property
            guard allKeys.contains(where: { $0.stringValue == key.stringValue}) else {
                
                throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "No value associated with key \(key.stringValue)."))
            }
            
            // get value
            return container.value(forKey: key.stringValue)
        }
    }
}

// MARK: - SingleValueDecodingContainer

fileprivate extension CoreDataDecoder {
    
    fileprivate struct AttributeSingleValueDecodingContainer: Swift.SingleValueDecodingContainer {
        
        // MARK: Properties
        
        /// A reference to the encoder we're reading from.
        private let decoder: CoreDataDecoder.Decoder
        
        /// A reference to the container we're reading from.
        private let container: Any
        
        /// The path of coding keys taken to get to this point in decoding.
        public let codingPath: [CodingKey]
        
        // MARK: Initialization
        
        /// Initializes `self` by referencing the given decoder and container.
        fileprivate init(referencing decoder: CoreDataDecoder.Decoder, wrapping container: Any) {
            
            self.decoder = decoder
            self.container = container
            self.codingPath = decoder.codingPath
        }
        
        // MARK: SingleValueDecodingContainer
        
        func decodeNil() -> Bool {
            
            return false
        }
        
        func decode(_ type: Bool.Type) throws -> Bool {
            
            return try self.decoder.unbox(container, as: type)
        }
        
        func decode(_ type: Int.Type) throws -> Int {
            
            let nativeValue = try self.decoder.unbox(container, as: NSNumber.self)
            
            return try self.decoder.unbox(nativeValue)
        }
        
        func decode(_ type: Int8.Type) throws -> Int8 {
            
            let nativeValue = try self.decoder.unbox(container, as: NSNumber.self)
            
            return try self.decoder.unbox(nativeValue)
        }
        
        func decode(_ type: Int16.Type) throws -> Int16 {
            
            return try self.decoder.unbox(container, as: type)
        }
        
        func decode(_ type: Int32.Type) throws -> Int32 {
            
            return try self.decoder.unbox(container, as: type)
        }
        
        func decode(_ type: Int64.Type) throws -> Int64 {
            
            return try self.decoder.unbox(container, as: type)
        }
        
        func decode(_ type: UInt.Type) throws -> UInt {
            
            let nativeValue = try self.decoder.unbox(container, as: NSNumber.self)
            
            return try self.decoder.unbox(nativeValue)
        }
        
        func decode(_ type: UInt8.Type) throws -> UInt8 {
            
            let nativeValue = try self.decoder.unbox(container, as: NSNumber.self)
            
            return try self.decoder.unbox(nativeValue)
        }
        
        func decode(_ type: UInt16.Type) throws -> UInt16 {
            
            let nativeValue = try self.decoder.unbox(container, as: NSNumber.self)
            
            return try self.decoder.unbox(nativeValue)
        }
        
        func decode(_ type: UInt32.Type) throws -> UInt32 {
            
            let nativeValue = try self.decoder.unbox(container, as: NSNumber.self)
            
            return try self.decoder.unbox(nativeValue)
        }
        
        func decode(_ type: UInt64.Type) throws -> UInt64 {
            
            let nativeValue = try self.decoder.unbox(container, as: NSNumber.self)
            
            return try self.decoder.unbox(nativeValue)
        }
        
        func decode(_ type: Float.Type) throws -> Float {
            
            return try self.decoder.unbox(container, as: type)
        }
        
        func decode(_ type: Double.Type) throws -> Double {
            
            return try self.decoder.unbox(container, as: type)
        }
        
        func decode(_ type: String.Type) throws -> String {
            
            return try self.decoder.unbox(container, as: type)
        }
        
        func decode<T : Decodable>(_ type: T.Type) throws -> T {
            
            return try self.decoder.unboxDecodable(container, as: type)
        }
    }
}

fileprivate extension CoreDataDecoder {
    
    fileprivate struct RelationshipSingleValueDecodingContainer: Swift.SingleValueDecodingContainer {
        
        // MARK: Properties
        
        /// A reference to the encoder we're reading from.
        private let decoder: CoreDataDecoder.Decoder
        
        /// A reference to the container we're reading from.
        private let container: NSManagedObject
        
        /// The path of coding keys taken to get to this point in decoding.
        public let codingPath: [CodingKey]
        
        // MARK: Initialization
        
        /// Initializes `self` by referencing the given decoder and container.
        fileprivate init(referencing decoder: CoreDataDecoder.Decoder, wrapping container: NSManagedObject) {
            
            self.decoder = decoder
            self.container = container
            self.codingPath = decoder.codingPath
        }
        
        // MARK: SingleValueDecodingContainer
        
        func decodeNil() -> Bool {
            
            return false
        }
        
        func decode(_ type: Bool.Type) throws -> Bool {
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(type) value but found \(container.objectID.uriRepresentation()) instead."))
        }
        
        func decode(_ type: Int.Type) throws -> Int {
            
            // decode into CoreDataIdentifier
            let nativeValue = try self.decoder.unbox(container.decod, as: NSNumber.self)
            
            return try self.decoder.unbox(nativeValue)
        }
        
        func decode(_ type: Int8.Type) throws -> Int8 {
            
            let nativeValue = try self.decoder.unbox(container, as: NSNumber.self)
            
            return try self.decoder.unbox(nativeValue)
        }
        
        func decode(_ type: Int16.Type) throws -> Int16 {
            
            return try self.decoder.unbox(container, as: type)
        }
        
        func decode(_ type: Int32.Type) throws -> Int32 {
            
            return try self.decoder.unbox(container, as: type)
        }
        
        func decode(_ type: Int64.Type) throws -> Int64 {
            
            return try self.decoder.unbox(container, as: type)
        }
        
        func decode(_ type: UInt.Type) throws -> UInt {
            
            let nativeValue = try self.decoder.unbox(container, as: NSNumber.self)
            
            return try self.decoder.unbox(nativeValue)
        }
        
        func decode(_ type: UInt8.Type) throws -> UInt8 {
            
            let nativeValue = try self.decoder.unbox(container, as: NSNumber.self)
            
            return try self.decoder.unbox(nativeValue)
        }
        
        func decode(_ type: UInt16.Type) throws -> UInt16 {
            
            let nativeValue = try self.decoder.unbox(container, as: NSNumber.self)
            
            return try self.decoder.unbox(nativeValue)
        }
        
        func decode(_ type: UInt32.Type) throws -> UInt32 {
            
            let nativeValue = try self.decoder.unbox(container, as: NSNumber.self)
            
            return try self.decoder.unbox(nativeValue)
        }
        
        func decode(_ type: UInt64.Type) throws -> UInt64 {
            
            let nativeValue = try self.decoder.unbox(container, as: NSNumber.self)
            
            return try self.decoder.unbox(nativeValue)
        }
        
        func decode(_ type: Float.Type) throws -> Float {
            
            return try self.decoder.unbox(container, as: type)
        }
        
        func decode(_ type: Double.Type) throws -> Double {
            
            return try self.decoder.unbox(container, as: type)
        }
        
        func decode(_ type: String.Type) throws -> String {
            
            return try self.decoder.unbox(container, as: type)
        }
        
        func decode<T : Decodable>(_ type: T.Type) throws -> T {
            
            return try self.decoder.unboxDecodable(container, as: type)
        }
        
        // MARK: Private Methods
        
        @inline(__always)
        private func decodedIdentifier() throws -> Any {
            
            guard let identifier = container as? DecodableManagedObject else {
                
                
            }
            
            return identifier
        }
    }
}

// MARK: - OLD

/*
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
                    
                    // read relationship value
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
