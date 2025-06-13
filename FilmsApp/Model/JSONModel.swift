import Foundation
import RealmSwift

class Item: Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var testTitle: String = ""
    @objc dynamic var testYeah: String = ""
    @objc dynamic var testRating: String = ""
    @objc dynamic var testPic: String = ""
    @objc dynamic var isLiked: Bool = false

    override static func primaryKey() -> String? {
        return "id"
    }
}
