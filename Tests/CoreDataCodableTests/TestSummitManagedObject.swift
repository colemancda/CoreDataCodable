//
//  TestSummitManagedObject.swift
//  CoreDataCodable
//
//  Created by Alsey Coleman Miller on 11/6/17.
//  Copyright © 2017 ColemanCDA. All rights reserved.
//


import Foundation
import CoreData

/// Base CoreData Entity `NSManagedObject` subclass for CoreSummit.
open class Entity: NSManagedObject {
    
    /// The unique identifier of this entity.
    @NSManaged open var identifier: Int64
    
    /// The date this object was stored in its entirety.
    @NSManaged open var cached: Date?
}

public extension Entity {
    
    static var identifierProperty: String { return "identifier" }
    
    func didCache() {
        
        self.cached = Date()
    }
    
    static func entity(in context: NSManagedObjectContext) -> NSEntityDescription {
        
        let className = NSStringFromClass(self as AnyClass)
        
        struct Cache {
            static var entities = [String: NSEntityDescription]()
        }
        
        // try to get from cache
        if let entity = Cache.entities[className] {
            
            return entity
        }
        
        // search for entity with class name
        guard let entity = context.persistentStoreCoordinator?.managedObjectModel[self]
            else { fatalError("Could not find entity") }
        
        Cache.entities[className] = entity
        
        return entity
    }
}

public final class SummitManagedObject: Entity {
    
    /// The date this summit was fetched from the server.
    @NSManaged public var initialDataLoad: Date?
    
    @NSManaged public var name: String
    
    @NSManaged public var timeZone: String
    
    @NSManaged public var datesLabel: String?
    
    @NSManaged public var start: Date
    
    @NSManaged public var end: Date
    
    @NSManaged public var defaultStart: Date?
    
    @NSManaged public var webpageURL: String
    
    @NSManaged public var active: Bool
    
    @NSManaged public var startShowingVenues: Date?
    
    @NSManaged public var sponsors: Set<CompanyManagedObject>
    
    @NSManaged public var speakers: Set<SpeakerManagedObject>
    
    @NSManaged public var ticketTypes: Set<TicketTypeManagedObject>
    
    @NSManaged public var locations: Set<LocationManagedObject>
    
    @NSManaged public var tracks: Set<TrackManagedObject>
    
    @NSManaged public var trackGroups: Set<TrackGroupManagedObject>
    
    @NSManaged public var eventTypes: Set<EventTypeManagedObject>
    
    @NSManaged public var schedule: Set<EventManagedObject>
    
    @NSManaged public var wirelessNetworks: Set<WirelessNetworkManagedObject>
}


