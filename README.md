# CoreDataCodable

`CoreDataCodable` framework provides a `CoreDataEncoder` and `CoreDataDecoder` to encode and decode Swift `Codable` types to CoreData `NSManagedObject`.

# How to use

For `Codable` types you will need to implement a couple protocols to provide the necesary information for CoreData serialization. 

- `CoreDataIdentifier`: In order for the encoder and decoder to fetch `NSManagedObject` for a to-one or to-many relationship, create a custom value type that conforms to `CoreDataIdentifier` and implement its methods. An identifier can be ay attribute value except `Bool`.
- `CoreDataCodable`: The value type (e.g. `struct`) that represents your entity should implement this protocol, as well as any to-one or to-many relationships that come as nested values.

# Properties

The `Encoder` and `Decoder` supports to-one and to-many relationships, as well as all supported CoreData attribute types (except `Transformable`). 

```
struct Entity: Codable, CoreDataCodable {
    
    struct Identifier: Codable, RawRepresentable, CoreDataIdentifier {
        
        var rawValue: String
        
        init(rawValue: String) {
            
            self.rawValue = rawValue
        }
    }
    
    enum Device: String, Codable {
        
        case iPhone, iPad, Mac
    }
    
    var identifier: Identifier
    
    var boolean: Bool
    
    var data: Data
    
    var date: Date
    
    var decimal: Decimal
    
    var double: Double
    
    var float: Float
    
    var int16: Int16
    
    var int32: Int32
    
    var int64: Int64
    
    var string: String
    
    var uri: URL
    
    var uuid: UUID
    
    var device: Device
    
    var optional: String?
    
    var toOneIdentifier: OtherEntity.Identifier?
    
    var toManyIdentifiers: [OtherEntity.Identifier]
    
    var toOneNested: OtherEntity?
    
    var toManyNested: [OtherEntity]
}

struct OtherEntity: Codable, CoreDataCodable {
    
    struct Identifier: Codable, RawRepresentable, CoreDataIdentifier {
        
        var rawValue: Int64
        
        init(rawValue: Int64) {
            
            self.rawValue = rawValue
        }
    }
    
    var identifier: Identifier
}
```