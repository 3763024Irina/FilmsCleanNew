import Foundation
import UIKit

class PreviewImageCell: UICollectionViewCell {
    static let identifier = "PreviewImageCell"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 8
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with urlString: String) {
        guard let url = URL(string: urlString) else {
            self.imageView.image = nil
            return
        }

        // Проверяем кэш
        if let cachedResponse = URLCache.shared.cachedResponse(for: URLRequest(url: url)),
           let image = UIImage(data: cachedResponse.data) {
            DispatchQueue.main.async {
                self.imageView.image = image
            }
            return
        }

        // Если нет в кэше — загружаем
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let data = data,
                let response = response,
                ((response as? HTTPURLResponse)?.statusCode ?? 500) < 300,
                let image = UIImage(data: data)
            else {
                return
            }

            // Кэшируем
            let cachedData = CachedURLResponse(response: response, data: data)
            URLCache.shared.storeCachedResponse(cachedData, for: URLRequest(url: url))

            DispatchQueue.main.async {
                self.imageView.image = image
            }
        }.resume()
    }
}
