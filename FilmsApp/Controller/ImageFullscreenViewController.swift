import UIKit
import RealmSwift

class ImageFullscreenViewController: UIViewController, UIScrollViewDelegate {

    // MARK: - Входные данные
    var image: UIImage?
    var imageUrl: URL?
    var itemId: Int?

    var imageBaseURL: String = "https://image.tmdb.org/t/p/"
    var posterSize: String = "w780"

    private let scrollView = UIScrollView()
    private let imageView = UIImageView()

    private let realm = try! Realm()
    static let imageCache = NSCache<NSURL, UIImage>()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupScrollView()
        setupGestureRecognizers()
        loadAndDisplayImage()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateZoomScale()
        centerImage()
    }

    private func setupScrollView() {
        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.bounces = true
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = true
        view.addSubview(scrollView)

        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        scrollView.addSubview(imageView)
    }

    private func setupGestureRecognizers() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }

    private func loadAndDisplayImage() {
        if let img = image {
            setImage(img)
            return
        }

        if let url = imageUrl {
            if let cached = Self.imageCache.object(forKey: url as NSURL) {
                setImage(cached)
            } else {
                loadImage(from: url)
            }
            return
        }

        if let id = itemId,
           let item = realm.object(ofType: Item.self, forPrimaryKey: id),
           !item.testPic.isEmpty {

            let base = imageBaseURL.hasSuffix("/") ? imageBaseURL : imageBaseURL + "/"
            let size = posterSize.hasSuffix("/") ? String(posterSize.dropLast()) : posterSize
            let path = item.testPic.hasPrefix("/") ? String(item.testPic.dropFirst()) : item.testPic
            let urlString = base + size + "/" + path

            guard let url = URL(string: urlString) else {
                setImage(UIImage(named: "placeholder"))
                return
            }

            if let cached = Self.imageCache.object(forKey: url as NSURL) {
                setImage(cached)
            } else {
                loadImage(from: url)
            }
            return
        }

        setImage(UIImage(named: "placeholder"))
    }

    private func loadImage(from url: URL) {
        imageView.image = UIImage(named: "placeholder")

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self,
                  let data = data,
                  error == nil,
                  let downloadedImage = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self?.setImage(UIImage(named: "placeholder"))
                }
                return
            }

            Self.imageCache.setObject(downloadedImage, forKey: url as NSURL)
            DispatchQueue.main.async {
                self.setImage(downloadedImage)
            }
        }.resume()
    }

    private func setImage(_ image: UIImage?) {
        guard let img = image else { return }

        imageView.image = img
        imageView.frame = CGRect(origin: .zero, size: img.size)
        scrollView.contentSize = img.size

        updateZoomScale()
        centerImage()
    }

    private func updateZoomScale() {
        guard let image = imageView.image else { return }

        let widthScale = scrollView.bounds.width / image.size.width
        let heightScale = scrollView.bounds.height / image.size.height
        let minScale = min(widthScale, heightScale)

        scrollView.minimumZoomScale = minScale
        scrollView.zoomScale = minScale
    }

    private func centerImage() {
        let imageViewSize = imageView.frame.size
        let scrollViewSize = scrollView.bounds.size

        let horizontalInset = max(0, (scrollViewSize.width - imageViewSize.width) / 2)
        let verticalInset = max(0, (scrollViewSize.height - imageViewSize.height) / 2)

        scrollView.contentInset = UIEdgeInsets(top: verticalInset, left: horizontalInset,
                                               bottom: verticalInset, right: horizontalInset)
    }

    // MARK: - UIScrollViewDelegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }
}
