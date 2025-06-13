import UIKit
import RealmSwift

class ImageFullscreenViewController: UIViewController, UIScrollViewDelegate {

    // Можно задать одно из этих значений:
    var image: UIImage?          // Если картинка передана напрямую
    var imageUrl: URL?           // Если картинка по URL
    var itemId: Int?             // Для загрузки из Realm, если URL нужно формировать

    // Для формирования URL из itemId
    var imageBaseURL: String = "https://image.tmdb.org/t/p/"
    var posterSize: String = "w500"

    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let realm = try! Realm()

    // Кэш изображений (используем NSURL ключ, так безопаснее)
    static let imageCache = NSCache<NSURL, UIImage>()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupScrollView()
        setupGesture()
        loadAndDisplayImage()
    }

    private func setupScrollView() {
        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        view.addSubview(scrollView)

        imageView.contentMode = .scaleAspectFit
        imageView.frame = scrollView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.addSubview(imageView)
    }

    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }

    private func loadAndDisplayImage() {
        // 1. Если есть image напрямую — сразу показываем
        if let directImage = image {
            imageView.image = directImage
            return
        }

        // 2. Если есть URL — грузим по нему с кешем
        if let url = imageUrl {
            if let cached = Self.imageCache.object(forKey: url as NSURL) {
                imageView.image = cached
                return
            }
            loadImage(from: url)
            return
        }

        // 3. Если есть itemId — пытаемся сформировать URL из Realm и загрузить
        if let id = itemId,
           let item = realm.object(ofType: Item.self, forPrimaryKey: id),
           !item.testPic.isEmpty {  // заменили if let на проверку пустой строки

            // Формируем полный URL
            let baseURL = imageBaseURL.hasSuffix("/") ? imageBaseURL : imageBaseURL + "/"
            let sanitizedSize = posterSize.hasSuffix("/") ? String(posterSize.dropLast()) : posterSize
            let cleanedPath = item.testPic.hasPrefix("/") ? String(item.testPic.dropFirst()) : item.testPic
            let urlString = baseURL + sanitizedSize + "/" + cleanedPath

            guard let url = URL(string: urlString) else {
                imageView.image = UIImage(named: "placeholder")
                return
            }

            if let cached = Self.imageCache.object(forKey: url as NSURL) {
                imageView.image = cached
            } else {
                loadImage(from: url)
            }
            return
        }

        // 4. Если ничего нет — плейсхолдер
        imageView.image = UIImage(named: "placeholder")
    }

    private func loadImage(from url: URL) {
        imageView.image = UIImage(named: "placeholder")
        print("📸 Загрузка изображения: \(url.absoluteString)")

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self,
                  let data = data,
                  let downloadedImage = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self?.imageView.image = UIImage(named: "placeholder")
                }
                return
            }

            Self.imageCache.setObject(downloadedImage, forKey: url as NSURL)

            DispatchQueue.main.async {
                self.imageView.image = downloadedImage
            }
        }.resume()
    }

    // MARK: - UIScrollViewDelegate

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
