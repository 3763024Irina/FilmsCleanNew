import UIKit
import RealmSwift

class Item: Object {
    @objc dynamic var id = 0
    @objc dynamic var testTitle = ""
    @objc dynamic var testYeah = ""
    @objc dynamic var testRating = ""
    @objc dynamic var testPic = ""  // полный URL картинки
    @objc dynamic var testDescription = "" // Описание фильма
    @objc dynamic var isLiked = false
    let testPreviewPictures = List<String>() // Превью-изображения

    override static func primaryKey() -> String? {
        return "id"
    }

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
        if let overview = dict["overview"] as? String {
            testDescription = overview
        }

        // Превьюшки (опционально)
        if let previews = dict["preview_images"] as? [String] {
            testPreviewPictures.removeAll()
            testPreviewPictures.append(objectsIn: previews)
        }
    }

    func getFullDescription() -> String {
        return "\(testTitle)\nРейтинг: \(testRating)\nГод выпуска: \(testYeah)\nОписание: \(testDescription)"
    }
}

// MARK: - Computed properties
extension Item {
    /// Извлекает путь к изображению из полного URL, если он соответствует формату TMDb
    var posterPath: String? {
        guard let pathComponent = testPic.components(separatedBy: "/t/p/").last else {
            return nil
        }
        return "/" + pathComponent.components(separatedBy: "/").last!
    }
}
