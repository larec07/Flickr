import Foundation

// Same to `Encodable` encode and `Decodable` init?. Convert to dictionary representation and
// decode from dictionary.
extension FlickrPhoto {
    // Dictionary representation
    var dictionary: [String: Any] {
        return ["id": id,
                "secret": secret,
                "server": server,
                "farm": farm,
                "title": title]
    }
    
    init?(from dictionary: [String: Any]) {
        if let id_ = dictionary["id"] as? String { id = id_ } else { return nil}
        if let secret_ = dictionary["secret"] as? String { secret = secret_ } else { return nil}
        if let server_ = dictionary["server"] as? String { server = server_ } else { return nil}
        if let farm_ = dictionary["farm"] as? Int { farm = farm_ } else { return nil}
        if let title_ = dictionary["title"] as? String { title = title_ } else { return nil}
    }
}
