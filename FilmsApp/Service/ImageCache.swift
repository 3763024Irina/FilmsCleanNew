//
//  ImageCache.swift
//  FilmsApp
//
//  Created by Irina on 17/6/25.
//

import Foundation
import UIKit

class ImageCache {
    static let shared = ImageCache()
    
    private let cache = NSCache<NSURL, UIImage>()
    
    private init() {}

    func image(for url: URL) -> UIImage? {
        return cache.object(forKey: url as NSURL)
    }

    func setImage(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }

    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        // Проверяем кеш
        if let cachedImage = image(for: url) {
            completion(cachedImage)
            return
        }

        // Загружаем из сети
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            self.setImage(image, for: url)
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
}
