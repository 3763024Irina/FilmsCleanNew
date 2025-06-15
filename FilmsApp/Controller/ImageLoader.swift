import UIKit

final class ImageLoader {

    static let shared = ImageLoader()

    private let imageBaseURL = "https://image.tmdb.org/t/p"
    private let posterSize = "w780"

    private let imageCache = NSCache<NSString, UIImage>()

    private init() {}

    func loadImage(from path: String, completion: @escaping (UIImage?) -> Void) {
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(imageBaseURL)/\(posterSize)/\(trimmed)") else {
            completion(nil)
            return
        }

        if let cachedImage = imageCache.object(forKey: url.absoluteString as NSString) {
            completion(cachedImage)
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard
                let self = self,
                let data = data,
                error == nil,
                let image = UIImage(data: data)
            else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            self.imageCache.setObject(image, forKey: url.absoluteString as NSString)
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
}
