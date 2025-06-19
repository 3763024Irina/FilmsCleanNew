import UIKit

final class ImageLoader {
    
    static let shared = ImageLoader()
    
    private let imageBaseURL = "https://image.tmdb.org/t/p"
    private let defaultSize = "w780"
    
    private let imageCache = NSCache<NSString, UIImage>()
    
    private init() {}

    /// Формирует URL изображения TMDb
    func buildImageURL(from path: String?, size: String) -> URL? {
        guard let path = path else { return nil }
        let trimmedPath = path.hasPrefix("/") ? path : "/\(path)"
        let urlString = "\(imageBaseURL)/\(size)\(trimmedPath)"
        return URL(string: urlString)
    }
    
    /// Загружает изображение с кэшированием
    /// - Parameters:
    ///   - path: Относительный путь изображения TMDb (например, "/abc123.jpg")
    ///   - size: Размер изображения (например, "w342", "w780"). По умолчанию "w780".
    ///   - completion: Обратный вызов с UIImage или ошибкой
    func loadImage(from path: String?, size: String? = nil, completion: @escaping (UIImage?, Error?) -> Void) {
        let imageSize = size ?? defaultSize
        
        guard let url = buildImageURL(from: path, size: imageSize) else {
            completion(nil, NSError(domain: "ImageLoaderError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }

        // Проверка кэша
        if let cachedImage = imageCache.object(forKey: url.absoluteString as NSString) {
            completion(cachedImage, nil)
            return
        }

        // Загрузка изображения
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }

            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    completion(nil, NSError(domain: "ImageLoaderError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to load image data"]))
                }
                return
            }

            // Кэширование и возврат
            self.imageCache.setObject(image, forKey: url.absoluteString as NSString)
            DispatchQueue.main.async {
                completion(image, nil)
            }
        }.resume()
    }
}
