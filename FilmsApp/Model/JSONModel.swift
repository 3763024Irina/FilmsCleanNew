import Foundation
import RealmSwift

class Item: Object {
    @objc dynamic var id = 0
    @objc dynamic var testTitle = ""
    @objc dynamic var testYeah = ""
    @objc dynamic var testRating = ""
    @objc dynamic var testPic = ""  // сюда будет полный URL картинки
    @objc dynamic var isLiked = false

    override static func primaryKey() -> String? {
        return "id"
    }

    private let baseImageURL = "https://image.tmdb.org/t/p/w780"

    func update(from dict: [String: Any]) {
        if let title = dict["title"] as? String {
            testTitle = title
        }
        if let date = dict["release_date"] as? String, date.count >= 4 {
            testYeah = String(date.prefix(4))
        }
        if let rating = dict["vote_average"] as? Double {
            testRating = String(format: "%.1f", rating)
        }
        if let posterPath = dict["poster_path"] as? String {
                testPic = "https://image.tmdb.org/t/p/w780" + posterPath
            } else {
                testPic = ""
        }
    }
}
