//
//  TestSummitManagedObject.swift
//  CoreDataCodable
//
//  Created by Alsey Coleman Miller on 11/6/17.
//  Copyright © 2017 ColemanCDA. All rights reserved.
//


import Foundation
import CoreData
import CoreDataCodable

/// Base CoreData Entity `NSManagedObject` subclass for CoreSummit.
open class Entity: NSManagedObject {
    
    /// The unique identifier of this entity.
    @NSManaged var identifier: Int64
    
    /// The date this object was stored in its entirety.
    @NSManaged var cached: Date?
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

extension NSManagedObjectModel {
    
    subscript(managedObjectType: NSManagedObject.Type) -> NSEntityDescription? {
        
        // search for entity with class name
        
        let className = NSStringFromClass(managedObjectType)
        
        return self.entities.first { $0.managedObjectClassName == className }
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
    
    @NSManaged public var webpage: String
    
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

public final class CompanyManagedObject: Entity {
    
    @NSManaged public var name: String
    
    // Inverse Relationships
    
    @NSManaged public var events: Set<EventManagedObject>
    
    @NSManaged public var summits: Set<SummitManagedObject>
}

public final class EventManagedObject: Entity {
    
    @NSManaged public var name: String
    
    @NSManaged public var descriptionText: String?
    
    @NSManaged public var socialDescription: String?
    
    @NSManaged public var start: Date
    
    @NSManaged public var end: Date
    
    @NSManaged public var allowFeedback: Bool
    
    @NSManaged public var averageFeedback: Double
    
    @NSManaged public var rsvp: String?
    
    @NSManaged public var externalRSVP: Bool
    
    @NSManaged public var willRecord: Bool
    
    @NSManaged public var attachment: String?
    
    @NSManaged public var track: TrackManagedObject?
    
    @NSManaged public var eventType: EventTypeManagedObject
    
    @NSManaged public var sponsors: Set<CompanyManagedObject>
    
    @NSManaged public var tags: Set<TagManagedObject>
    
    @NSManaged public var location: LocationManagedObject?
    
    @NSManaged public var presentation: PresentationManagedObject
    
    @NSManaged public var videos: Set<VideoManagedObject>
    
    @NSManaged public var slides: Set<SlideManagedObject>
    
    @NSManaged public var links: Set<LinkManagedObject>
    
    @NSManaged public var groups: Set<GroupManagedObject>
    
    @NSManaged public var summit: SummitManagedObject
    
    // MARK: - Inverse Relationhips
    
    @NSManaged public var members: Set<MemberManagedObject>
}

public final class EventTypeManagedObject: Entity {
    
    @NSManaged public var name: String
    
    @NSManaged public var color: String
    
    @NSManaged public var blackOutTimes: Bool
    
    // Inverse Relationships
    
    @NSManaged public var events: Set<EventManagedObject>
    
    @NSManaged public var summits: Set<SummitManagedObject>
}

public final class GroupManagedObject: Entity {
    
    @NSManaged public var title: String
    
    @NSManaged public var descriptionText: String?
    
    @NSManaged public var code: String
}

open class LocationManagedObject: Entity {
    
    @NSManaged open var name: String
    
    @NSManaged open var descriptionText: String?
    
    // Inverse Relationships
    
    @NSManaged open var events: Set<EventManagedObject>
    
    @NSManaged open var summit: SummitManagedObject
}

public final class VenueManagedObject: LocationManagedObject {
    
    @NSManaged public var venueType: String
    
    @NSManaged public var locationType: String
    
    @NSManaged public var country: String
    
    @NSManaged public var address: String?
    
    @NSManaged public var city: String?
    
    @NSManaged public var zipCode: String?
    
    @NSManaged public var state: String?
    
    @NSManaged public var latitude: String?
    
    @NSManaged public var longitude: String?
    
    @NSManaged public var images: Set<ImageManagedObject>
    
    @NSManaged public var maps: Set<ImageManagedObject>
    
    @NSManaged public var floors: Set<VenueFloorManagedObject>
}

public final class VenueRoomManagedObject: LocationManagedObject {
    
    @NSManaged public var capacity: NSNumber?
    
    @NSManaged public var venue: VenueManagedObject
    
    @NSManaged public var floor: VenueFloorManagedObject?
}

public final class VenueFloorManagedObject: Entity {
    
    @NSManaged public var name: String
    
    @NSManaged public var descriptionText: String?
    
    @NSManaged public var number: Int16
    
    @NSManaged public var imageURL: String?
    
    @NSManaged public var venue: VenueManagedObject
    
    @NSManaged public var rooms: Set<VenueRoomManagedObject>
}

public final class ImageManagedObject: Entity {
    
    @NSManaged public var url: String
}

public final class PresentationManagedObject: Entity {
    
    @NSManaged public var level: String?
    
    @NSManaged public var track: TrackManagedObject?
    
    @NSManaged public var moderator: SpeakerManagedObject?
    
    @NSManaged public var speakers: Set<SpeakerManagedObject>
    
    // Inverse Relationships
    
    @NSManaged public var event: EventManagedObject
}

public final class TrackManagedObject: Entity {
    
    @NSManaged public var name: String
    
    @NSManaged public var groups: Set<TrackGroupManagedObject>
    
    // Inverse Relationships
    
    @NSManaged public var events: Set<EventManagedObject>
    
    @NSManaged public var summits: Set<SummitManagedObject>
}

public final class TrackGroupManagedObject: Entity {
    
    @NSManaged public var name: String
    
    @NSManaged public var descriptionText: String?
    
    @NSManaged public var color: String
    
    @NSManaged public var tracks: Set<TrackManagedObject>
    
    // Inverse Relationships
    
    @NSManaged public var summits: Set<SummitManagedObject>
}


public final class SpeakerManagedObject: Entity {
    
    @NSManaged public var firstName: String
    
    @NSManaged public var lastName: String
    
    @NSManaged public var addressBookSectionName: String
    
    @NSManaged public var title: String?
    
    @NSManaged public var pictureURL: String
    
    @NSManaged public var twitter: String?
    
    @NSManaged public var irc: String?
    
    @NSManaged public var biography: String?
    
    @NSManaged public var affiliations: Set<AffiliationManagedObject>
    
    // Inverse Relationships
    
    @NSManaged public var summits: Set<SummitManagedObject>
    
    @NSManaged public var presentationModerator: Set<PresentationManagedObject>
    
    @NSManaged public var presentationSpeaker: Set<PresentationManagedObject>
}

public final class SummitTypeManagedObject: Entity {
    
    @NSManaged public var name: String
    
    @NSManaged public var color: String
}

public final class TicketTypeManagedObject: Entity {
    
    @NSManaged public var name: String
    
    @NSManaged public var descriptionText: String?
}

public final class TagManagedObject: Entity {
    
    @NSManaged public var name: String
}

public final class VideoManagedObject: Entity {
    
    @NSManaged public var name: String
    
    @NSManaged public var descriptionText: String?
    
    @NSManaged public var displayOnSite: Bool
    
    @NSManaged public var featured: Bool
    
    @NSManaged public var youtube: String
    
    @NSManaged public var order: Int64
    
    @NSManaged public var views: Int64
    
    @NSManaged public var highlighted: Bool
    
    @NSManaged public var dataUploaded: Date
    
    @NSManaged public var event: EventManagedObject
}

public final class SlideManagedObject: Entity {
    
    @NSManaged public var name: String
    
    @NSManaged public var descriptionText: String?
    
    @NSManaged public var displayOnSite: Bool
    
    @NSManaged public var featured: Bool
    
    @NSManaged public var order: Int64
    
    @NSManaged public var link: String
    
    @NSManaged public var event: EventManagedObject
}

public final class LinkManagedObject: Entity {
    
    @NSManaged public var name: String
    
    @NSManaged public var descriptionText: String?
    
    @NSManaged public var displayOnSite: Bool
    
    @NSManaged public var featured: Bool
    
    @NSManaged public var order: Int64
    
    @NSManaged public var link: String
    
    @NSManaged public var event: EventManagedObject
}

public final class WirelessNetworkManagedObject: Entity {
    
    @NSManaged public var name: String
    
    @NSManaged public var password: String
    
    @NSManaged public var descriptionText: String?
    
    @NSManaged public var summit: SummitManagedObject
}

public final class AffiliationManagedObject: Entity {
    
    @NSManaged public var member: MemberManagedObject
    
    @NSManaged public var start: Date?
    
    @NSManaged public var end: Date?
    
    @NSManaged public var isCurrent: Bool
    
    @NSManaged public var organization: AffiliationOrganizationManagedObject
}

public final class AffiliationOrganizationManagedObject: Entity {
    
    @NSManaged public var name: String
}

public final class MemberManagedObject: Entity {
    
    @NSManaged public var firstName: String
    
    @NSManaged public var lastName: String
    
    @NSManaged public var gender: String?
    
    @NSManaged public var pictureURL: String
    
    @NSManaged public var twitter: String?
    
    @NSManaged public var linkedIn: String?
    
    @NSManaged public var irc: String?
    
    @NSManaged public var biography: String?
    
    @NSManaged public var speakerRole: SpeakerManagedObject?
    
    @NSManaged public var attendeeRole: AttendeeManagedObject?
    
    @NSManaged public var schedule: Set<EventManagedObject>
    
    @NSManaged public var groups: Set<GroupManagedObject>
    
    @NSManaged public var groupEvents: Set<EventManagedObject>
    
    @NSManaged public var feedback: Set<FeedbackManagedObject>
    
    @NSManaged public var favoriteEvents: Set<EventManagedObject>
    
    @NSManaged public var affiliations: Set<AffiliationManagedObject>
}

public final class AttendeeManagedObject: Entity {
    
    @NSManaged public var member: MemberManagedObject
    
    @NSManaged public var tickets: Set<TicketTypeManagedObject>
}

open class FeedbackManagedObject: Entity {
    
    @NSManaged open var rate: Int16
    
    @NSManaged open var review: String
    
    @NSManaged open var date: Date
    
    @NSManaged open var event: EventManagedObject
    
    @NSManaged open var member: MemberManagedObject
}

