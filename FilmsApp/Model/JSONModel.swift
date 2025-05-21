import Foundation
import UIKit

class Item {
    var id: Int?
    var testTitle: String?
    var testYeah: String?
    var testRating: String?
    var testPic: String?
    var isLiked: Bool

    init(id: Int?, testPic: String?, testTitle: String?, testYeah: String?, testRating: String?, isLiked: Bool) {
        self.id = id
        self.testPic = testPic
        self.testTitle = testTitle
        self.testYeah = testYeah
        self.testRating = testRating
        self.isLiked = isLiked
    }
}

class Model {
    var testArray: [Item] = [
        Item(id: 0, testPic: "image1", testTitle: "Inception", testYeah: "2010", testRating: "8.8", isLiked: false),
        Item(id: 1, testPic: "image2", testTitle: "Titanic", testYeah: "1997", testRating: "7.8", isLiked: false),
        Item(id: 2, testPic: "image3", testTitle: "Avatar", testYeah: "2009", testRating: "7.9", isLiked: false),
        Item(id: 3, testPic: "image4", testTitle: "The Dark Knight", testYeah: "2008", testRating: "9.0", isLiked: true),
        Item(id: 4, testPic: "image5", testTitle: "Forrest Gump", testYeah: "1994", testRating: "8.8", isLiked: false),
        Item(id: 5, testPic: "image6", testTitle: "The Matrix", testYeah: "1999", testRating: "8.7", isLiked: true),
        Item(id: 6, testPic: "image7", testTitle: "The Shawshank Redemption", testYeah: "1994", testRating: "9.3", isLiked: true),
        Item(id: 7, testPic: "image8", testTitle: "Gladiator", testYeah: "2000", testRating: "8.5", isLiked: false),
        Item(id: 8, testPic: "image9", testTitle: "The Godfather", testYeah: "1972", testRating: "9.2", isLiked: false),
        Item(id: 9, testPic: "image10", testTitle: "The Lion King", testYeah: "1994", testRating: "8.5", isLiked: true),
        Item(id: 10, testPic: "image11", testTitle: "Pulp Fiction", testYeah: "1994", testRating: "8.9", isLiked: false),
        Item(id: 11, testPic: "image12", testTitle: "Fight Club", testYeah: "1999", testRating: "8.8", isLiked: true),
        Item(id: 12, testPic: "image13", testTitle: "Interstellar", testYeah: "2014", testRating: "8.6", isLiked: false),
        Item(id: 13, testPic: "image14", testTitle: "Рабыня Изаура", testYeah: "1985", testRating: "9.0", isLiked: false),
        Item(id: 14, testPic: "image15", testTitle: "Добрыня Никитич", testYeah: "2000", testRating: "9.5", isLiked: false)
    ]
}
