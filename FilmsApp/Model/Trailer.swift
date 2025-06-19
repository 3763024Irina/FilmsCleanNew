import Foundation
import RealmSwift
struct Trailer: Codable {
    let id: String
    let key: String
    let name: String
    let site: String
    let type: String
}

struct VideoResponse: Codable {
    let results: [Trailer]
}


class TrailerObject: Object {
    @Persisted(primaryKey: true) var id: String = ""
    @Persisted var key: String = ""
    @Persisted var name: String = ""
    @Persisted var site: String = ""
    @Persisted var type: String = ""

    convenience init(trailer: Trailer) {
        self.init()
        self.id = trailer.id
        self.key = trailer.key
        self.name = trailer.name
        self.site = trailer.site
        self.type = trailer.type
    }

    func toTrailer() -> Trailer {
        Trailer(id: id, key: key, name: name, site: site, type: type)
    }
}
