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

/// [OpenStack Summit](https://github.com/OpenStack-mobile/summit-app-ios)
public struct SummitResponse {
    
    public var summit: Summit
    
    public struct Summit: Codable {
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
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
        
        public var wirelessNetworks: [WirelessNetwork]
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
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
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
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        private enum CodingKeys: String, CodingKey {
            
            case identifier = "id"
            case name
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
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        private enum CodingKeys: String, CodingKey {
            
            case identifier = "id"
            case member = "owner_id"
            case start = "start_date"
            case end = "end_date"
            case isCurrent = "is_current"
            case organization
        }
        
        public let identifier: Identifier
        
        public var member: Identifier
        
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
        
        private enum CodingKeys: String, CodingKey {
            
            case identifier = "id"
            case name
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
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        private enum CodingKeys: String, CodingKey {
            
            case identifier = "id"
            case url = "image_url"
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
        
        public init(from decoder: Decoder) throws {
            
            
        }
        
        public func encode(to encoder: Encoder) throws {
            
            fatalError()
        }
    }
    
    public struct Venue: Codable {
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
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
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
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
        
        public struct Identifier: Codable, RawRepresentable {
            
            public var rawValue: Int64
            
            public init(rawValue: Int64) {
                
                self.rawValue = rawValue
            }
        }
        
        private enum CodingKeys: String, CodingKey {
            
            case identifier = "id"
            case summit = "summit_id"
            case title
            case descriptionText = "description"
            case socialDescription = "social_description"
            case start = "start_date"
            case end = "end_date"
            case allowFeedback = "allow_feedback"
            case averageFeedback = "avg_feedback_rate"
            case type = "type_id"
            case sponsors
            case speakers
            case location = "location_id"
            case tags
            case track = "track_id"
            case videos
            case rsvp = "rsvp_link"
            case groups
            case externalRSVP = "rsvp_external"
            case willRecord = "to_record"
            case attachment
            case slides
            case links
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
        
        public var externalRSVP: Bool = false
        
        public var willRecord: Bool = false
        
        public var attachment: URL?
        
        public var sponsors: [Company.Identifier]
        
        public var tags: [Tag]
        
        public var location: Location.Identifier?
        
        public var presentation: Presentation
        
        public var videos: [Video]
        
        public var slides: [Slide]
        
        public var links: [Link]
        
        // Never comes from this JSON
        //public var groups: [Group]
        
        // Presentation values
        
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
        
        public var name: String
        
        public var descriptionText: String?
        
        public var displayOnSite: Bool
        
        public var featured: Bool
        
        public var order: Int64
        
        public var link: URL
        
        public var event: Event.Identifier
    }
}

