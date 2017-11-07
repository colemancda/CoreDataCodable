//
//  TestSummitModel.swift
//  CoreDataCodable
//
//  Created by Alsey Coleman Miller on 11/6/17.
//  Copyright © 2017 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
import CoreDataCodable

public struct Model {
    
    public struct Summit: Codable {
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        public let identifier: Identifier
        
        public var name: String
        
        public var timeZone: String
        
        public var datesLabel: String?
        
        public var start: Date
        
        public var end: Date
        
        /// Default start date for the Summit.
        public var defaultStart: Date?
        
        public var active: Bool
        
        public var webpage: URL
        
        public var sponsors: [Company]
        
        public var speakers: [Speaker]
        
        public var startShowingVenues: Date?
        
        public var ticketTypes: [TicketType]
        
        // Venue and Venue Rooms
        public var locations: [Location]
        
        public var tracks: [Track]
        
        public var trackGroups: [TrackGroup]
        
        public var eventTypes: [EventType]
        
        public var schedule: [Event]
        
        public var wirelessNetworks: [WirelessNetwork]
    }
    
    public struct WirelessNetwork: Codable {
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        public let identifier: Identifier
        
        public let name: String
        
        public let password: String
        
        public let descriptionText: String?
        
        public let summit: Summit.Identifier
    }
    
    public struct Company: Codable {
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        public let identifier: Identifier
        
        public var name: String
    }
    
    public struct Speaker: Codable {
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        public let identifier: Identifier
        
        public var firstName: String
        
        public var lastName: String
        
        public var title: String?
        
        public var picture: URL
        
        public var twitter: String?
        
        public var irc: String?
        
        public var biography: String?
        
        public var affiliations: [Affiliation]
    }
    
    public struct Affiliation: Codable {
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        public let identifier: Identifier
        
        public var member: Model.Member.Identifier
        
        public var start: Date?
        
        public var end: Date?
        
        public var isCurrent: Bool
        
        public var organization: AffiliationOrganization
    }
    
    public struct AffiliationOrganization: Codable {
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        public let identifier: Identifier
        
        public var name: String
    }
    
    public struct TicketType: Codable {
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        public let identifier: Identifier
        
        public var name: String
        
        public var descriptionText: String?
    }
    
    public struct Image: Codable {
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        public let identifier: Identifier
        
        public var url: URL
    }
    
    public enum Location: Codable {
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        case venue(Venue)
        case room(VenueRoom)
        
        public var identifier: Identifier {
            
            switch self {
            case let .venue(venue): return Identifier(rawValue: venue.identifier.rawValue)
            case let .room(room): return Identifier(rawValue: room.identifier.rawValue)
            }
        }
        
        public init(from decoder: Decoder) throws {
            
            if let venue = try? Venue(from: decoder) {
                
                self = .venue(venue)
                
            } else if let room = try? VenueRoom(from: decoder) {
                
                self = .room(room)
                
            } else {
                
                struct InvalidLocationError: Error {
                    
                    let context: DecodingError.Context
                }
                
                throw InvalidLocationError(context: DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Could not decode location."))
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            
            switch self {
            case let .venue(venue): return try venue.encode(to: encoder)
            case let .room(room): return try room.encode(to: encoder)
            }
        }
    }
    
    public struct Venue: Codable {
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        public enum LocationType: String, Codable {
            
            case Internal, External, None
        }
        
        public enum ClassName: String, Codable {
            
            case SummitVenue, SummitExternalLocation, SummitHotel, SummitAirport
        }
        
        public let identifier: Identifier
        
        public let type: ClassName
        
        public var name: String
        
        public var descriptionText: String?
        
        public var locationType: LocationType
        
        public var country: String
        
        public var address: String?
        
        public var city: String?
        
        public var zipCode: String?
        
        public var state: String?
        
        public var latitude: String?
        
        public var longitude: String?
        
        public var maps: [Image]
        
        public var images: [Image]
        
        public var floors: [VenueFloor]
    }
    
    public struct VenueFloor: Codable {
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        private enum CodingKeys: String, CodingKey {
            
            case identifier = "id"
            case name
            case descriptionText = "description"
            case number
            case image
            case venue = "venue_id"
            case rooms
        }
        
        public let identifier: Identifier
        
        public var name: String
        
        public var descriptionText: String?
        
        public var number: Int16
        
        public var image: URL?
        
        public var venue: Image.Identifier
        
        public var rooms: [VenueRoom.Identifier]
    }
    
    public struct VenueRoom: Codable {
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        public enum ClassName: String, Codable {
            
            case SummitVenueRoom
        }
        
        private enum CodingKeys: String, CodingKey {
            
            case identifier = "id"
            case name
            case descriptionText = "description"
            case type = "class_name"
            case capacity
            case venue = "venue_id"
            case floor = "floor_id"
        }
        
        public let identifier: Identifier
        
        public let type: ClassName
        
        public var name: String
        
        public var descriptionText: String?
        
        public var capacity: Int?
        
        public var venue: Venue.Identifier
        
        public var floor: VenueFloor.Identifier?
    }
    
    public struct Track: Codable {
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        private enum CodingKeys: String, CodingKey {
            
            case identifier = "id"
            case name
            case groups = "track_groups"
        }
        
        public let identifier: Identifier
        
        public var name: String
        
        public var groups: [TrackGroup.Identifier]
    }
    
    public struct TrackGroup: Codable {
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        public let identifier: Identifier
        
        public var name: String
        
        public var descriptionText: String?
        
        public var color: String
        
        public var tracks: [Track.Identifier]
    }
    
    public struct EventType: Codable {
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        public let identifier: Identifier
        
        public var name: String
        
        public var color: String
        
        public var blackOutTimes: Bool
    }
    
    public struct Event: Codable {
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        public let identifier: Identifier
        
        public var name: String
        
        public var summit: Identifier
        
        public var descriptionText: String?
        
        public var socialDescription: String?
        
        public var start: Date
        
        public var end: Date
        
        public var track: Identifier?
        
        public var allowFeedback: Bool
        
        public var averageFeedback: Double
        
        public var type: Identifier
        
        public var rsvp: String?
        
        public var externalRSVP: Bool?
        
        public var willRecord: Bool?
        
        public var attachment: URL?
        
        public var sponsors: [Company.Identifier]
        
        public var tags: [Tag]
        
        public var location: Location.Identifier?
        
        public var videos: [Video]
        
        public var slides: [Slide]
        
        public var links: [Link]
        
        // Never comes from this JSON
        //public var groups: [Group]
        
        // Presentation values
        
        // created from self
        public var presentation: Presentation
    }
    
    public struct Presentation: Codable {
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        public let identifier: Identifier
        
        public var level: Level?
        
        public var moderator: Speaker.Identifier?
        
        public var speakers: [Speaker.Identifier]
    }
    
    public enum Level: String, Codable {
        
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case notApplicable = "N/A"
    }
    
    public struct Link: Codable {
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        public let identifier: Identifier
        
        public var name: String?
        
        public var descriptionText: String?
        
        public var displayOnSite: Bool
        
        public var featured: Bool
        
        public var order: Int64
        
        public var link: String // not always valid URL
        
        public var event: Event.Identifier
    }
    
    public struct Tag: Codable {
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        public let identifier: Identifier
        
        public var name: String
    }
    
    public struct Video: Codable {
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        public let identifier: Identifier
        
        public var name: String
        
        public var descriptionText: String?
        
        public var displayOnSite: Bool
        
        public var featured: Bool
        
        public var highlighted: Bool
        
        public var youtube: String
        
        public var dataUploaded: Date
        
        public var order: Int64
        
        public var views: Int64
        
        public var event: Event.Identifier
    }
    
    public struct Slide: Codable {
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        public let identifier: Identifier
        
        public var name: String?
        
        public var descriptionText: String?
        
        public var displayOnSite: Bool
        
        public var featured: Bool
        
        public var order: Int64
        
        public var link: URL
        
        public var event: Identifier
    }
    
    public struct Member: Codable {
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        public let identifier: Identifier
        
        public let firstName: String
        
        public let lastName: String
        
        public let gender: String?
        
        public let picture: URL
        
        public let twitter: String?
        
        public let linkedIn: String?
        
        public let irc: String?
        
        public let biography: String?
        
        public let speakerRole: Speaker?
        
        public let attendeeRole: Attendee?
        
        public var schedule: [Event.Identifier]
        
        public let groupEvents: [Event.Identifier]
        
        public let favoriteEvents: [Event.Identifier]
        
        public let groups: [Group]
        
        public let feedback: [Feedback.Identifier]
        
        public let affiliations: [Affiliation]
    }
    
    public struct Attendee: Codable {
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        public let identifier: Identifier
        
        public var member: Member.Identifier
        
        public var tickets: [TicketType.Identifier]
    }
    
    public struct Group: Codable {
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        public let identifier: Identifier
        
        public var title: String
        
        public var descriptionText: String?
        
        public var code: String
    }
    
    public struct Feedback: Codable {
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        public let identifier: Identifier
        
        public let rate: Int
        
        public let review: String
        
        public let date: Date
        
        public let event: Event.Identifier
        
        public let member: Member
    }
}

// MARK: - SummitUnique

public protocol SummitUnique {
    
    associatedtype Identifier: Codable, RawRepresentable
    
    var identifier: Identifier { get }
}

extension SummitUnique where Self: CoreDataCodable, Self.Identifier: CoreDataIdentifier {
    
    // All identifier properties should be same as summit
    public static var identifierKey: CodingKey { return Model.Summit.identifierKey }
    
    public var coreDataIdentifier: CoreDataIdentifier { return identifier }
}

extension Model.Summit: SummitUnique { }
extension Model.WirelessNetwork: SummitUnique { }
extension Model.Company: SummitUnique { }
extension Model.Speaker: SummitUnique { }
extension Model.Affiliation: SummitUnique { }
extension Model.AffiliationOrganization: SummitUnique { }
extension Model.TicketType: SummitUnique { }
extension Model.Image: SummitUnique { }
extension Model.Location: SummitUnique { }
extension Model.Venue: SummitUnique { }
extension Model.VenueRoom: SummitUnique { }
extension Model.VenueFloor: SummitUnique { }
extension Model.Track: SummitUnique { }
extension Model.TrackGroup: SummitUnique { }
extension Model.Event: SummitUnique { }
extension Model.EventType: SummitUnique { }
extension Model.Presentation: SummitUnique { }
extension Model.Link: SummitUnique { }
extension Model.Tag: SummitUnique { }
extension Model.Video: SummitUnique { }
extension Model.Slide: SummitUnique { }

// MARK: - CoreDataIdentifier

public protocol SummitCoreDataIdentifier: CoreDataIdentifier {
    
    associatedtype ManagedObject: Entity
}

extension SummitCoreDataIdentifier where Self: RawRepresentable, Self.RawValue == Int64 {
    
    public func findOrCreate(in context: NSManagedObjectContext) throws -> NSManagedObject {
        
        let entityName = ManagedObject.entity(in: context).name!
        
        return try context.findOrCreate(identifier: self.rawValue as NSNumber,
                                        property: "identifier",
                                        entityName: entityName)
    }
    
    public init?(managedObject: NSManagedObject) {
        
        guard let managedObject = managedObject as? ManagedObject
            else { return nil }
        
        self.init(rawValue: managedObject.identifier)
    }
}

extension Model.Summit.Identifier: SummitCoreDataIdentifier {
    
    public typealias ManagedObject = SummitManagedObject
}

extension Model.WirelessNetwork.Identifier: SummitCoreDataIdentifier {
    
    public typealias ManagedObject = WirelessNetworkManagedObject
}

extension Model.Company.Identifier: SummitCoreDataIdentifier {
    
    public typealias ManagedObject = CompanyManagedObject
}

extension Model.Speaker.Identifier: SummitCoreDataIdentifier {
    
    public typealias ManagedObject = SpeakerManagedObject
}

extension Model.Affiliation.Identifier: SummitCoreDataIdentifier {
    
    public typealias ManagedObject = AffiliationManagedObject
}

extension Model.AffiliationOrganization.Identifier: SummitCoreDataIdentifier {
    
    public typealias ManagedObject = AffiliationOrganizationManagedObject
}

extension Model.TicketType.Identifier: SummitCoreDataIdentifier {
    
    public typealias ManagedObject = TicketTypeManagedObject
}

extension Model.Image.Identifier: SummitCoreDataIdentifier {
    
    public typealias ManagedObject = ImageManagedObject
}

extension Model.Location.Identifier: SummitCoreDataIdentifier {
    
    public typealias ManagedObject = LocationManagedObject
}

extension Model.Venue.Identifier: SummitCoreDataIdentifier {
    
    public typealias ManagedObject = VenueManagedObject
}

extension Model.VenueRoom.Identifier: SummitCoreDataIdentifier {
    
    public typealias ManagedObject = VenueRoomManagedObject
}

extension Model.VenueFloor.Identifier: SummitCoreDataIdentifier {
    
    public typealias ManagedObject = VenueFloorManagedObject
}

extension Model.Track.Identifier: SummitCoreDataIdentifier {
    
    public typealias ManagedObject = TrackManagedObject
}

extension Model.TrackGroup.Identifier: SummitCoreDataIdentifier {
    
    public typealias ManagedObject = TrackGroupManagedObject
}

extension Model.Event.Identifier: SummitCoreDataIdentifier {
    
    public typealias ManagedObject = EventManagedObject
}

extension Model.EventType.Identifier: SummitCoreDataIdentifier {
    
    public typealias ManagedObject = EventTypeManagedObject
}

extension Model.Presentation.Identifier: SummitCoreDataIdentifier {
    
    public typealias ManagedObject = PresentationManagedObject
}

extension Model.Link.Identifier: SummitCoreDataIdentifier {
    
    public typealias ManagedObject = LinkManagedObject
}

extension Model.Tag.Identifier: SummitCoreDataIdentifier {
    
    public typealias ManagedObject = TagManagedObject
}

extension Model.Video.Identifier: SummitCoreDataIdentifier {
    
    public typealias ManagedObject = VideoManagedObject
}

extension Model.Slide.Identifier: SummitCoreDataIdentifier {
    
    public typealias ManagedObject = SlideManagedObject
}

// MARK: - CoreDataCodable

extension Model.Summit: CoreDataCodable {
    
    public static var identifierKey: CodingKey { return CodingKeys.identifier }
}

extension Model.WirelessNetwork: CoreDataCodable { }
extension Model.Company: CoreDataCodable { }
extension Model.Speaker: CoreDataCodable { }
extension Model.Affiliation: CoreDataCodable { }
extension Model.AffiliationOrganization: CoreDataCodable { }
extension Model.TicketType: CoreDataCodable { }
extension Model.Image: CoreDataCodable { }
extension Model.Location: CoreDataCodable { }
extension Model.Venue: CoreDataCodable { }
extension Model.VenueRoom: CoreDataCodable { }
extension Model.VenueFloor: CoreDataCodable { }
extension Model.Track: CoreDataCodable { }
extension Model.TrackGroup: CoreDataCodable { }
extension Model.Event: CoreDataCodable { }
extension Model.EventType: CoreDataCodable { }
extension Model.Presentation: CoreDataCodable { }
extension Model.Link: CoreDataCodable { }
extension Model.Tag: CoreDataCodable { }
extension Model.Video: CoreDataCodable { }
extension Model.Slide: CoreDataCodable { }

