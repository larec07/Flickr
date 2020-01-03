import Foundation

struct FlickrPhoto: Decodable {
    let id: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
}

// Приложение никак не желало encode -ить структуру FlickrPhoto в момент архивации.
// С наскока выяснить причину не удалось. Ввиду спешки решил не тратить время на изучение вопроса.
// Решил расширить FlickrPhoto и добавить возможность конвертации Dictionary <-> FlickrPhoto.
// В файле FlickrPhotoCoding.swift
// Закомментированный код удалять не стал.

//extension FlickrPhoto: Codable {
//    enum CodingKeys: String, CodingKey {
//        case id
//        case secret
//        case server
//        case farm
//        case title
//    }
//
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//
//        id     = try container.decode(String.self, forKey: .id)
//        secret = try container.decode(String.self, forKey: .secret)
//        server = try container.decode(String.self, forKey: .server)
//        farm   = try container.decode(Int.self, forKey: .farm)
//        title  = try container.decode(String.self, forKey: .title)
//    }
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//
//        try container.encode(id, forKey: .id)
//        try container.encode(secret, forKey: .secret)
//        try container.encode(server, forKey: .server)
//        try container.encode(farm, forKey: .farm)
//        try container.encode(title, forKey: .title)
//    }
//}

struct FlickrPhotos: Decodable {
    let page: UInt
    let pages: UInt
    let perpage: UInt
    let total: UInt
    let photo: [FlickrPhoto]
}

struct FlickrResponse: Decodable {
    let photos: FlickrPhotos
    let stat: String
}
