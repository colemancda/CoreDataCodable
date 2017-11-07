//
//  TestSummit.swift
//  CoreDataCodable
//
//  Created by Alsey Coleman Miller on 11/6/17.
//  Copyright © 2017 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
import CoreDataCodable

// MARK: - JSON

/// [OpenStack Summit](https://github.com/OpenStack-mobile/summit-app-ios)
public struct SummitResponse: Codable, RawRepresentable {
    
    public var rawValue: Summit
    
    public init(rawValue: Summit) {
        
        self.rawValue = rawValue
    }
    
    public struct Summit: Codable {
        
        public typealias Identifier = Model.Summit.Identifier
        
        private enum CodingKeys: String, CodingKey {
            
            case identifier = "id"
            case name
            case timeZone = "time_zone"
            case datesLabel = "dates_label"
            case start = "start_date"
            case end = "end_date"
            case defaultStart = "schedule_start_date"
            case active
            case webpage = "page_url"
            case sponsors
            case speakers
            case startShowingVenues = "start_showing_venues_date"
            case ticketTypes = "ticket_types"
            case locations
            case tracks
            case trackGroups = "track_groups"
            case eventTypes = "event_types"
            case schedule
            case wirelessNetworks = "wifi_connections"
        }
        
        public let identifier: Identifier
        
        public var name: String
        
        public var timeZone: TimeZone
        
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
        
        public var wirelessNetworks: [WirelessNetwork]?
    }
    
    public struct TimeZone: Codable {
        
        private enum CodingKeys: String, CodingKey {
            
            case name
            case countryCode = "country_code"
            case latitude
            case longitude
            case comments
            case offset
        }
        
        public var name: String
        
        public var countryCode: String
        
        public var latitude: Double
        
        public var longitude: Double
        
        public var comments: String
        
        public var offset: Int
    }
    
    public struct WirelessNetwork: Codable {
        
        public typealias Identifier = Model.WirelessNetwork.Identifier
        
        private enum CodingKeys: String, CodingKey {
            
            case identifier = "id"
            case name = "ssid"
            case password
            case descriptionText = "description"
            case summit = "summit_id"
        }
        
        public let identifier: Identifier
        
        public let name: String
        
        public let password: String
        
        public let descriptionText: String?
        
        public let summit: Summit.Identifier
    }
    
    public struct Company: Codable {
        
        public typealias Identifier = Model.Company.Identifier
        
        private enum CodingKeys: String, CodingKey {
            
            case identifier = "id"
            case name
        }
        
        public let identifier: Identifier
        
        public var name: String
    }
    
    public struct Speaker: Codable {
        
        public typealias Identifier = Model.Speaker.Identifier
        
        public enum CodingKeys: String, CodingKey {
            
            case identifier = "id"
            case firstName = "first_name"
            case lastName = "last_name"
            case title
            case picture = "pic"
            case twitter
            case irc
            case biography = "bio"
            case affiliations
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
        
        public typealias Identifier = Model.Affiliation.Identifier
        
        private enum CodingKeys: String, CodingKey {
            
            case identifier = "id"
            case member = "owner_id"
            case start = "start_date"
            case end = "end_date"
            case isCurrent = "is_current"
            case organization
        }
        
        public let identifier: Identifier
        
        public var member: Member.Identifier
        
        public var start: Date?
        
        public var end: Date?
        
        public var isCurrent: Bool
        
        public var organization: AffiliationOrganization
    }
    
    public struct AffiliationOrganization: Codable {
        
        public typealias Identifier = Model.AffiliationOrganization.Identifier
        
        private enum CodingKeys: String, CodingKey {
            
            case identifier = "id"
            case name
        }
        
        public let identifier: Identifier
        
        public var name: String
    }
    
    public struct TicketType: Codable {
        
        public typealias Identifier = Model.TicketType.Identifier
        
        private enum CodingKeys: String, CodingKey {
            
            case identifier = "id"
            case name
            case descriptionText = "description"
        }
        
        public let identifier: Identifier
        
        public var name: String
        
        public var descriptionText: String?
    }
    
    public struct Image: Codable {
        
        public typealias Identifier = Model.Image.Identifier
        
        private enum CodingKeys: String, CodingKey {
            
            case identifier = "id"
            case url = "image_url"
        }
        
        public let identifier: Identifier
        
        public var url: URL
    }
    
    public enum Location: Codable {
        
        public typealias Identifier = Model.Location.Identifier
        
        public enum ClassName: String, Codable {
            
            case SummitVenue, SummitExternalLocation, SummitHotel, SummitAirport, SummitVenueRoom
        }
        
        private enum CodingKeys: String, CodingKey {
            
            case type = "class_name"
        }
        
        case venue(Venue)
        case room(VenueRoom)
        
        public init(from decoder: Decoder) throws {
            
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            let type = try container.decode(ClassName.self, forKey: .type)
            
            switch type {
                
            case .SummitVenue, .SummitExternalLocation, .SummitHotel, .SummitAirport:
                
                let venue = try Venue(from: decoder)
                
                self = .venue(venue)
                
            case .SummitVenueRoom:
                
                let room = try VenueRoom(from: decoder)
                
                self = .room(room)
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            
            fatalError()
        }
    }
    
    public struct Venue: Codable {
        
        public typealias Identifier = Model.Venue.Identifier
        
        public typealias LocationType = Model.Venue.LocationType
        
        public typealias ClassName = Model.Venue.ClassName
        
        private enum CodingKeys: String, CodingKey {
            
            case identifier = "id"
            case name
            case latitude = "lat"
            case longitude = "lng"
            case address = "address_1"
            case city
            case state
            case zipCode = "zip_code"
            case country
            case maps
            case images
            case floors
            case locationType = "location_type"
            case descriptionText = "description"
            case type = "class_name"
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
        
        public var floors: [VenueFloor]?
    }
    
    public struct VenueFloor: Codable {
        
        public typealias Identifier = Model.VenueFloor.Identifier
        
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
        
        public var rooms: [VenueRoom.Identifier]?
    }
    
    public struct VenueRoom: Codable {
        
        public typealias Identifier = Model.VenueRoom.Identifier
        
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
        
        public typealias Identifier = Model.Track.Identifier
        
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
        
        public typealias Identifier = Model.TrackGroup.Identifier
        
        private enum CodingKeys: String, CodingKey {
            
            case identifier = "id"
            case name
            case descriptionText = "description"
            case color
            case tracks
        }
        
        public let identifier: Identifier
        
        public var name: String
        
        public var descriptionText: String?
        
        public var color: String
        
        public var tracks: [Track.Identifier]
    }
    
    public struct EventType: Codable {
        
        public typealias Identifier = Model.EventType.Identifier
        
        private enum CodingKeys: String, CodingKey {
            
            case identifier = "id"
            case name
            case color
            case blackOutTimes = "black_out_times"
        }
        
        public let identifier: Identifier
        
        public var name: String
        
        public var color: String
        
        public var blackOutTimes: Bool
    }
    
    public struct Event: Codable {
        
        public typealias Identifier = Model.Event.Identifier
        
        private enum CodingKeys: String, CodingKey {
            
            case identifier = "id"
            case summit = "summit_id"
            case name = "title"
            case descriptionText = "description"
            case socialDescription = "social_description"
            case start = "start_date"
            case end = "end_date"
            case allowFeedback = "allow_feedback"
            case averageFeedback = "avg_feedback_rate"
            case type = "type_id"
            case sponsors
            case location = "location_id"
            case tags
            case track = "track_id"
            case videos
            case rsvp = "rsvp_link"
            case externalRSVP = "rsvp_external"
            case willRecord = "to_record"
            case attachment
            case slides
            case links
            
            // presentation
            case level
            case moderator = "moderator_speaker_id"
            case speakers
        }
        
        public let identifier: Identifier
        
        public var name: String
        
        public var summit: Identifier
        
        public var descriptionText: String?
        
        public var socialDescription: String?
        
        public var start: Date
        
        public var end: Date
        
        public var track: Track.Identifier?
        
        public var allowFeedback: Bool
        
        public var averageFeedback: Double
        
        public var type: EventType.Identifier
        
        public var rsvp: String?
        
        public var externalRSVP: Bool?
        
        public var willRecord: Bool?
        
        public var attachment: URL?
        
        public var sponsors: [Company.Identifier]
        
        public var tags: [Tag]
        
        public var location: Location.Identifier?
        
        // Not really a different entity
        //public var presentation: Presentation
        
        public var videos: [Video]?
        
        public var slides: [Slide]?
        
        public var links: [Link]?
        
        // Never comes from this JSON
        //public var groups: [Group]
        
        // Presentation values
        
        public var level: Model.Level?
        
        public var moderator: Speaker.Identifier?
        
        public var speakers: [Speaker.Identifier]?
    }
    
    public struct Link: Codable {
        
        public typealias Identifier = Model.Link.Identifier
        
        private enum CodingKeys: String, CodingKey {
            
            case identifier = "id"
            case name
            case descriptionText = "description"
            case displayOnSite = "display_on_site"
            case featured
            case order
            case event = "presentation_id"
            case link
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
        
        public typealias Identifier = Model.Tag.Identifier
        
        private enum CodingKeys: String, CodingKey {
            
            case identifier = "id"
            case name = "tag"
        }
        
        public let identifier: Identifier
        
        public var name: String
    }
    
    public struct Video: Codable {
        
        public typealias Identifier = Model.Video.Identifier
        
        private enum CodingKeys: String, CodingKey {
            
            case identifier = "id"
            case name
            case descriptionText = "description"
            case displayOnSite = "display_on_site"
            case featured
            case event = "presentation_id"
            case youtube = "youtube_id"
            case dataUploaded = "data_uploaded"
            case highlighted
            case views
            case order
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
        
        public typealias Identifier = Model.Slide.Identifier
        
        private enum CodingKeys: String, CodingKey {
            
            case identifier = "id"
            case name
            case descriptionText = "description"
            case displayOnSite = "display_on_site"
            case featured
            case order
            case event = "presentation_id"
            case link
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
}

// MARK: - Model Conversion

public protocol SummitJSONDecodable {
    
    associatedtype JSONDecodable: Swift.Decodable
    
    init(jsonDecodable: JSONDecodable)
}

public extension Collection where Self.Iterator.Element: SummitJSONDecodable {
    
    static func from(_ jsonDecodables: [Self.Iterator.Element.JSONDecodable]?) -> [Self.Iterator.Element] {
        
        return jsonDecodables?.map { Self.Iterator.Element.init(jsonDecodable: $0) } ?? []
    }
}

extension Model.Summit: SummitJSONDecodable {
    
    public init(jsonDecodable json: SummitResponse.Summit) {
        
        self.identifier = json.identifier
        self.name = json.name
        self.timeZone = json.timeZone.name
        self.datesLabel = json.datesLabel
        self.start = json.start
        self.end = json.end
        self.defaultStart = json.defaultStart
        self.active = json.active
        self.webpage = json.webpage
        self.startShowingVenues = json.startShowingVenues
        self.sponsors = .from(json.sponsors)
        self.speakers = .from(json.speakers)
        self.ticketTypes = .from(json.ticketTypes)
        self.locations = .from(json.locations)
        self.tracks = .from(json.tracks)
        self.trackGroups = .from(json.trackGroups)
        self.eventTypes = .from(json.eventTypes)
        self.schedule = .from(json.schedule)
        self.wirelessNetworks = .from(json.wirelessNetworks)
    }
}

extension Model.Company: SummitJSONDecodable {
    
    public init(jsonDecodable json: SummitResponse.Company) {
        
        self.identifier = json.identifier
        self.name = json.name
    }
}

extension Model.Speaker: SummitJSONDecodable {
    
    public init(jsonDecodable json: SummitResponse.Speaker) {
        
        self.identifier = json.identifier
        self.firstName = json.firstName
        self.lastName = json.lastName
        self.title = json.title
        self.picture = json.picture
        self.twitter = json.twitter
        self.irc = json.irc
        self.biography = json.biography
        self.affiliations = .from(json.affiliations)
    }
}

extension Model.WirelessNetwork: SummitJSONDecodable {
    
    public init(jsonDecodable json: SummitResponse.WirelessNetwork) {
        
        self.identifier = json.identifier
        self.name = json.name
        self.password = json.password
        self.descriptionText = json.descriptionText
        self.summit = json.summit
    }
}

extension Model.Affiliation: SummitJSONDecodable {
    
    public init(jsonDecodable json: SummitResponse.Affiliation) {
        
        self.identifier = json.identifier
        self.member = json.member
        self.start = json.start
        self.end = json.end
        self.isCurrent = json.isCurrent
        self.organization = .init(jsonDecodable: json.organization)
    }
}

extension Model.AffiliationOrganization: SummitJSONDecodable {
    
    public init(jsonDecodable json: SummitResponse.AffiliationOrganization) {
        
        self.identifier = json.identifier
        self.name = json.name
    }
}

extension Model.TicketType: SummitJSONDecodable {
    
    public init(jsonDecodable json: SummitResponse.TicketType) {
        
        self.identifier = json.identifier
        self.name = json.name
        self.descriptionText = json.descriptionText
    }
}

extension Model.Image: SummitJSONDecodable {
    
    public init(jsonDecodable json: SummitResponse.Image) {
        
        self.identifier = json.identifier
        self.url = json.url
    }
}

extension Model.Location: SummitJSONDecodable {
    
    public init(jsonDecodable json: SummitResponse.Location) {
        
        switch json {
        case let .venue(jsonLocation):
            self = .venue(.init(jsonDecodable: jsonLocation))
        case let .room(jsonLocation):
            self = .room(.init(jsonDecodable: jsonLocation))
        }
    }
}

extension Model.Venue: SummitJSONDecodable {
    
    public init(jsonDecodable json: SummitResponse.Venue) {
        
        self.identifier = json.identifier
        self.type = json.type
        self.name = json.name
        self.descriptionText = json.descriptionText
        self.locationType = json.locationType
        self.country = json.country
        self.address = json.address
        self.city = json.city
        self.zipCode = json.zipCode
    }
}

extension Model.VenueRoom: SummitJSONDecodable {
    
    public init(jsonDecodable json: SummitResponse.VenueRoom) {
        
        self.identifier = json.identifier
    }
}

extension Model.VenueFloor: SummitJSONDecodable {
    
    public init(jsonDecodable json: SummitResponse.VenueFloor) {
        
        self.identifier = json.identifier
    }
}

extension Model.Track: SummitJSONDecodable {
    
    public init(jsonDecodable json: SummitResponse.Track) {
        
        self.identifier = json.identifier
    }
}

extension Model.TrackGroup: SummitJSONDecodable {
    
    public init(jsonDecodable json: SummitResponse.TrackGroup) {
        
        self.identifier = json.identifier
    }
}

extension Model.Event: SummitJSONDecodable {
    
    public init(jsonDecodable json: SummitResponse.Event) {
        
        self.identifier = json.identifier
    }
}

extension Model.EventType: SummitJSONDecodable {
    
    public init(jsonDecodable json: SummitResponse.EventType) {
        
        self.identifier = json.identifier
    }
}

extension Model.Presentation: SummitJSONDecodable {
    
    public init(jsonDecodable json: SummitResponse.Event) {
        
        self.identifier = json.identifier
    }
}

extension Model.Link: SummitJSONDecodable {
    
    public init(jsonDecodable json: SummitResponse.Link) {
        
        self.identifier = json.identifier
    }
}

extension Model.Tag: SummitJSONDecodable {
    
    public init(jsonDecodable json: SummitResponse.Tag) {
        
        self.identifier = json.identifier
    }
}

extension Model.Video: SummitJSONDecodable {
    
    public init(jsonDecodable json: SummitResponse.Video) {
        
        self.identifier = json.identifier
    }
}

extension Model.Slide: SummitJSONDecodable {
    
    public init(jsonDecodable json: SummitResponse.Slide) {
        
        self.identifier = json.identifier
    }
}

