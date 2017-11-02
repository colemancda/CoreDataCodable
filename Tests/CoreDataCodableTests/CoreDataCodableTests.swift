//
//  CoreDataCodableTests.swift
//  ColemanCDA
//
//  Created by Alsey Coleman Miller on 11/1/17.
//  Copyright © 2017 ColemanCDA. All rights reserved.
//

import Foundation
import XCTest
import CoreDataCodable

class CoreDataCodableTests: XCTestCase {
    
    static var allTests = [
        ("testExample", testExample),
    ]
    
    func testExample() {
        
        struct Test1: CoreDataEncodable {
            
            var id: UUID
            
            var name: String
            
            var value: Int
        }
    }
    
}
