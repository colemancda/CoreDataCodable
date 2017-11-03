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
        
        context {
            
            var encoder = CoreDataEncoder(managedObjectContext: $0)
            encoder.log = { print($0) }
            
            do {
                
                let managedObject = try encoder.encode(value) as! TestAttributesManagedObject
                
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
            }
            
            catch { XCTFail("\(error)") }
        }
    }
    
    func testFaultRelationship() {
        
        let parent = TestParent(identifier: TestParent.Identifier(rawValue: 100),
                                child: TestChild.Identifier(rawValue: UUID()),
                                children: [TestChild.Identifier(rawValue: UUID()),
                                           TestChild.Identifier(rawValue: UUID())])
        
        context {
            
            var encoder = CoreDataEncoder(managedObjectContext: $0)
            encoder.log = { print($0) }
            
            do {
                
                let managedObject = try encoder.encode(parent) as! TestParentManagedObject
                
                print(managedObject)
                
                XCTAssert(managedObject.identifier == parent.identifier.rawValue)
                XCTAssert(Set(managedObject.children.map({ $0.identifier })) == Set(parent.children.map({ $0.rawValue })))
                XCTAssert(managedObject.child?.identifier == parent.child?.rawValue)
            }
            
            catch { XCTFail("\(error)") }
        }
    }
    
    func testFulfilledRelationships() {
        
        let parentIdentifier = TestFullfilledParent.Identifier(rawValue: 100)
        
        let child = TestChild(identifier: TestChild.Identifier(rawValue: UUID()),
                              parent: nil,
                              parentToOne: parentIdentifier)
        
        let children = [
            TestChild(identifier: TestChild.Identifier(rawValue: UUID()), parent: parentIdentifier, parentToOne: nil),
            TestChild(identifier: TestChild.Identifier(rawValue: UUID()), parent: parentIdentifier, parentToOne: nil),
            TestChild(identifier: TestChild.Identifier(rawValue: UUID()), parent: parentIdentifier, parentToOne: nil)
        ]
        
        let parent = TestFullfilledParent(identifier: parentIdentifier,
                                child: child,
                                children: children)
        
        context {
            
            var encoder = CoreDataEncoder(managedObjectContext: $0)
            encoder.log = { print($0) }
            
            do {
                
                let managedObject = try encoder.encode(parent) as! TestParentManagedObject
                
                print(managedObject)
                
                XCTAssert(managedObject.identifier == parent.identifier.rawValue)
                XCTAssert(Set(managedObject.children.map({ $0.identifier })) == Set(parent.children.map({ $0.identifier.rawValue })))
                XCTAssert(managedObject.child?.identifier == parent.child?.identifier.rawValue)
            }
                
            catch { XCTFail("\(error)") }
        }
    }
}

extension CoreDataCodableTests {
    
    var model: NSManagedObjectModel {
        
        return NSManagedObjectModel.mergedModel(from: Bundle.allBundles)!
    }
    
    func testSQLiteURL() -> URL {
        
        let fileManager = FileManager.default
        
        // get cache folder
        
        let cacheURL = try! fileManager.url(for: .cachesDirectory,
                                            in: .userDomainMask,
                                            appropriateFor: nil,
                                            create: false)
        
        // get app folder
        let bundleIdentifier = "\(self)" //Bundle.main.bundleIdentifier!
        let folderURL = cacheURL.appendingPathComponent(bundleIdentifier, isDirectory: true)
        
        // create folder if doesnt exist
        var folderExists: ObjCBool = false
        if fileManager.fileExists(atPath: folderURL.path, isDirectory: &folderExists) == false
            || folderExists.boolValue == false {
            
            try! fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
        
        let fileURL = folderURL.appendingPathComponent("data" + UUID().uuidString + ".sqlite", isDirectory: false)
        
        return fileURL
    }
    
    func context(_ block: (NSManagedObjectContext) -> ()) {
        
        let fileURL = testSQLiteURL()
        
        let managedObjectModel = self.model
        
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.undoManager = nil
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        try! persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                           configurationName: nil,
                                                           at: fileURL,
                                                           options: nil)
        
        block(managedObjectContext)
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
