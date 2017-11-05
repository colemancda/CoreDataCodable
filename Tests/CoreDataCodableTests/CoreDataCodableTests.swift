//
//  CoreDataCodableTests.swift
//  ColemanCDA
//
//  Created by Alsey Coleman Miller on 11/1/17.
//  Copyright © 2017 ColemanCDA. All rights reserved.
//

import Foundation
import XCTest
import CoreData
import CoreDataCodable

final class CoreDataCodableTests: XCTestCase {
    
    func testAttributes() {
        
        let value = TestAttributes(identifier: TestAttributes.Identifier(rawValue: "test01"),
                                   boolean: true,
                                   data: Data(bytes: [0x01, 0x02, 0x03]),
                                   date: Date(),
                                   decimal: Decimal(100.555555),
                                   double: 1.66666,
                                   float: 1.5555,
                                   int16: 16,
                                   int32: 32,
                                   int64: 64,
                                   string: "test",
                                   uri: URL(string: "https://swift.org")!,
                                   uuid: UUID(),
                                   enumValue: .three,
                                   optional: nil)
        
        XCTAssertNoThrow(try context {
            
            var encoder = CoreDataEncoder(managedObjectContext: $0)
            encoder.log = { print($0) }
            
            print("Will encode")
            
            let managedObject = try encoder.encode(value) as! TestAttributesManagedObject
            
            print("Did encode")
            
            print(managedObject)
            
            XCTAssert(managedObject.identifier == value.identifier.rawValue)
            XCTAssert(managedObject.boolean == value.boolean)
            XCTAssert(managedObject.data == value.data)
            XCTAssert(managedObject.date == value.date)
            XCTAssert(managedObject.decimal.description == value.decimal.description) // NSDecimal bug?
            XCTAssert(managedObject.double == value.double)
            XCTAssert(managedObject.float == value.float)
            XCTAssert(managedObject.int16 == value.int16)
            XCTAssert(managedObject.int32 == value.int32)
            XCTAssert(managedObject.int64 == value.int64)
            XCTAssert(managedObject.string == value.string)
            XCTAssert(managedObject.uri == value.uri)
            XCTAssert(managedObject.uuid == value.uuid)
            XCTAssert(managedObject.enumValue == value.enumValue.rawValue)
            XCTAssertNil(managedObject.optional)
            
            var decoder = CoreDataDecoder(managedObjectContext: $0)
            decoder.log = { print($0) }
            
            print("Will decode")
            
            let decoded = try decoder.decode(TestAttributes.self, with: value.identifier)
            
            print("Did decode")
            
            XCTAssert(decoded.identifier == value.identifier)
            XCTAssert(decoded.boolean == value.boolean)
            XCTAssert(decoded.data == value.data)
            XCTAssert(decoded.date == value.date)
            XCTAssert(decoded.decimal == value.decimal)
            XCTAssert(decoded.double == value.double)
            XCTAssert(decoded.float == value.float)
            XCTAssert(decoded.int16 == value.int16)
            XCTAssert(decoded.int32 == value.int32)
            XCTAssert(decoded.int64 == value.int64)
            XCTAssert(decoded.string == value.string)
            XCTAssert(decoded.uri == value.uri)
            XCTAssert(decoded.uuid == value.uuid)
            XCTAssert(decoded.enumValue == value.enumValue)
            XCTAssertNil(decoded.optional)
            XCTAssert("\(decoded)" == "\(value)")
            
            try $0.save()
        })
    }
    
    func testFaultRelationship() {
        
        let parent = TestParent(identifier: TestParent.Identifier(rawValue: 100),
                                child: TestChild.Identifier(rawValue: "child01"),
                                children: [TestChild.Identifier(rawValue: "children01"),
                                           TestChild.Identifier(rawValue: "children02")])
        
        XCTAssertNoThrow(try context {
            
            var encoder = CoreDataEncoder(managedObjectContext: $0)
            encoder.log = { print($0) }
            
            print("Will encode")
            
            let managedObject = try encoder.encode(parent) as! TestParentManagedObject
            
            print("Did encode")
            
            print(managedObject)
            
            XCTAssert(managedObject.identifier == parent.identifier.rawValue)
            XCTAssert(Set(managedObject.children.map({ $0.identifier })) == Set(parent.children.map({ $0.rawValue })))
            XCTAssert(managedObject.child?.identifier == parent.child?.rawValue)
            
            var decoder = CoreDataDecoder(managedObjectContext: $0)
            decoder.log = { print($0) }
            
            print("Will decode")
            
            let decoded = try decoder.decode(TestParent.self, with: parent.identifier)
            
            print("Did decode")
            
            XCTAssert(decoded.identifier == parent.identifier)
            XCTAssert(decoded.child?.rawValue == parent.child?.rawValue)
            XCTAssert(Set(decoded.children.map({ $0.rawValue })) == Set(parent.children.map({ $0.rawValue })))
            
            try $0.save()
        })
    }
    
    func testFulfilledRelationships() {
        
        let parentIdentifier = TestFullfilledParent.Identifier(rawValue: 100)
        
        let child = TestChild(identifier: TestChild.Identifier(rawValue: "child01"),
                              parent: nil,
                              parentToOne: parentIdentifier)
        
        let children = [
            TestChild(identifier: TestChild.Identifier(rawValue: "children01"), parent: parentIdentifier, parentToOne: nil),
            TestChild(identifier: TestChild.Identifier(rawValue: "children02"), parent: parentIdentifier, parentToOne: nil),
            TestChild(identifier: TestChild.Identifier(rawValue: "children03"), parent: parentIdentifier, parentToOne: nil)
        ]
        
        let parent = TestFullfilledParent(identifier: parentIdentifier,
                                child: child,
                                children: children)
        
         XCTAssertNoThrow(try context {
            
            var encoder = CoreDataEncoder(managedObjectContext: $0)
            encoder.log = { print($0) }
            
            let managedObject = try encoder.encode(parent) as! TestParentManagedObject
            
            print(managedObject)
            
            XCTAssert(managedObject.identifier == parent.identifier.rawValue)
            XCTAssert(Set(managedObject.children.map({ $0.identifier })) == Set(parent.children.map({ $0.identifier.rawValue })))
            XCTAssert(managedObject.child?.identifier == parent.child?.identifier.rawValue)
            
            var decoder = CoreDataDecoder(managedObjectContext: $0)
            decoder.log = { print($0) }
            
            print("Will decode")
            
            let decoded = try decoder.decode(TestFullfilledParent.self, with: parent.identifier)
            
            print("Did decode")
            
            XCTAssert(decoded.identifier == parent.identifier)
            XCTAssert(String(describing: decoded.child) == String(describing: parent.child))
            XCTAssert(Set(decoded.children.map({ "\($0)" })) == Set(parent.children.map({ "\($0)" })))
            
            try $0.save()
        })
    }
    
    func testNested() {
        
        let parent = TestNested(identifier: 1, children: [
            TestNested(identifier: 21),
            TestNested(identifier: 22, children: [
                TestNested(identifier: 31, children: [
                    TestNested(identifier: 41, children: []),
                    ]),
                TestNested(identifier: 32, children: [
                    TestNested(identifier: 42)
                    ])
                ])
            ])
        
        XCTAssertNoThrow(try context {
            
            var encoder = CoreDataEncoder(managedObjectContext: $0)
            encoder.log = { print($0) }
            
            print("Will encode")
            
            let managedObject = try encoder.encode(parent) as! TestNestedManagedObject
            
            print("Did encode")
            
            print(managedObject)
            
            XCTAssert(managedObject.identifier == parent.identifier.rawValue)
            
            var decoder = CoreDataDecoder(managedObjectContext: $0)
            decoder.log = { print($0) }
            
            print("Will decode")
            
            let decoded = try decoder.decode(TestNested.self, with: parent.identifier)
            
            print("Did decode")
            
            XCTAssert(decoded.identifier == parent.identifier)
            XCTAssert(String(describing: decoded) == String(describing: parent))
            
            try $0.save()
        })
    }
}

extension CoreDataCodableTests {
    
    var model: NSManagedObjectModel {
        
        return NSManagedObjectModel.mergedModel(from: Bundle.allBundles)!
    }
    
    func testSQLiteURL(_ function: String = #function) -> URL {
        
        let fileManager = FileManager.default
        
        // get cache folder
        
        let cacheURL = try! fileManager.url(for: .cachesDirectory,
                                            in: .userDomainMask,
                                            appropriateFor: nil,
                                            create: false)
        
        // get app folder
        let folderURL = cacheURL.appendingPathComponent("CoreDataCodableTests", isDirectory: true)
        
        // create folder if doesnt exist
        var folderExists: ObjCBool = false
        if fileManager.fileExists(atPath: folderURL.path, isDirectory: &folderExists) == false
            || folderExists.boolValue == false {
            
            try! fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
        
        let fileURL = folderURL.appendingPathComponent(function + "." + UUID().uuidString + ".sqlite", isDirectory: false)
        
        print("Created SQLite file at \(fileURL)")
        
        return fileURL
    }
    
    func context <Result> (_ function: String = #function, _ block: (NSManagedObjectContext) throws -> Result) rethrows -> Result {
        
        let fileURL = testSQLiteURL(function)
        
        let managedObjectModel = self.model
        
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.undoManager = nil
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        try! persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                           configurationName: nil,
                                                           at: fileURL,
                                                           options: nil)
        
        return try block(managedObjectContext)
    }
}

extension NSManagedObjectContext {
    
    func findOrCreate<T: NSManagedObject>(identifier: NSObject, property: String, entityName: String) throws -> T {
        
        let fetchRequest = NSFetchRequest<T>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%K == %@", property, identifier)
        fetchRequest.fetchLimit = 1
        fetchRequest.includesSubentities = false
        fetchRequest.returnsObjectsAsFaults = true
        
        if let existing = try self.fetch(fetchRequest).first {
            
            return existing
            
        } else {
            
            // create a new entity
            let newManagedObject = NSEntityDescription.insertNewObject(forEntityName: entityName, into: self) as! T
            
            // set resource ID
            newManagedObject.setValue(identifier, forKey: property)
            
            return newManagedObject
        }
    }
}

protocol Unique {
    
    associatedtype Identifier: Codable, RawRepresentable
    
    var identifier: Identifier { get }
}

extension Unique where Self: CoreDataCodable, Self.Identifier: CoreDataIdentifier {
    
    static var identifierKey: String { return "identifier" }
    
    var coreDataIdentifier: CoreDataIdentifier { return self.identifier }
}
