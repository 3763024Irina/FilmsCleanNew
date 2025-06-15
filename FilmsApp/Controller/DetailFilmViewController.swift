import UIKit
import RealmSwift

protocol DetailFilmViewControllerDelegate: AnyObject {
    func didUpdateFilm(_ film: Item)
}

class DetailFilmViewController: UIViewController {
    
    enum TransitionProfile {
        case show, pop
    }
    
    var item: Item? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.film = self?.item
            }
        }
    }
    
    var film: Item? {
        didSet {
            DispatchQueue.main.async {
                self.configureWithFilm()
                self.updateLikeButton()
                self.loadPreviewImages()
            }
        }
    }
    
    var transitionProfile: TransitionProfile = .show
    var start: CGPoint = .zero
    var transition = RoundingTransition()
    var cameFromFav: Bool = false
    
    weak var delegate: DetailFilmViewControllerDelegate?
    
    private let realm: Realm = try! Realm()
    
    private static var imageCache = NSCache<NSString, UIImage>()
    private let imageBaseURL = "https://image.tmdb.org/t/p"
    private let posterSize = "w780"
    private let previewSize = "w300"
    
    private var previewImages: [String] = []
    
    // MARK: - UI Elements
    private let posterImageView = UIImageView()
    private let backdropImageView = UIImageView()
    private let titleLabel = UILabel()
    private let idLabel = UILabel()
    private let yearLabel = UILabel()
    private let ratingLabel = UILabel()
    private let overviewLabel = UILabel()
    private let likeButton = UIButton(type: .system)
    private let showAllImagesButton = UIButton(type: .system)
    
    private let previewImagesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 120, height: 80)
        layout.minimumLineSpacing = 8
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(PreviewImageCell.self, forCellWithReuseIdentifier: PreviewImageCell.identifier)
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupTransition()
        setupUI()
        setupCloseButton()
        setupLikeButton()
        setupDoubleTapGesture()
        previewImagesCollectionView.delegate = self
        previewImagesCollectionView.dataSource = self
    }
    
    private func buildImageURL(baseURL: String, size: String, path: String) -> URL? {
        var base = baseURL
        if base.hasSuffix("/") {
            base.removeLast()
        }
        var sizePart = size
        if sizePart.hasPrefix("/") {
            sizePart.removeFirst()
        }
        if sizePart.hasSuffix("/") {
            sizePart.removeLast()
        }
        var pathPart = path
        if !pathPart.hasPrefix("/") {
            pathPart = "/" + pathPart
        }
        let fullString = "\(base)/\(sizePart)\(pathPart)"
        return URL(string: fullString)
    }
    
    private func setupTransition() {
        transition.start = start
        transition.transitionProfile = .show
        transitioningDelegate = self
        modalPresentationStyle = .custom
    }
    
    private func setupUI() {
        [backdropImageView, posterImageView, likeButton,
         titleLabel, idLabel, yearLabel, ratingLabel,
         overviewLabel, previewImagesCollectionView,
         showAllImagesButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        posterImageView.contentMode = .scaleAspectFill
        posterImageView.clipsToBounds = true
        posterImageView.isUserInteractionEnabled = true
        posterImageView.layer.cornerRadius = 8
        
        backdropImageView.contentMode = .scaleAspectFill
        backdropImageView.clipsToBounds = true
        backdropImageView.layer.cornerRadius = 8
        backdropImageView.alpha = 0.4
        
        titleLabel.font = .boldSystemFont(ofSize: 22)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        
        idLabel.font = .italicSystemFont(ofSize: 14)
        idLabel.textColor = .gray
        
        yearLabel.font = .systemFont(ofSize: 18)
        ratingLabel.font = .systemFont(ofSize: 18)
        
        overviewLabel.font = .systemFont(ofSize: 16)
        overviewLabel.numberOfLines = 0
        
        likeButton.tintColor = .systemRed
        
        showAllImagesButton.setTitle("Все изображения >", for: .normal)
        showAllImagesButton.addTarget(self, action: #selector(showAllImagesTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            backdropImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backdropImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backdropImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            backdropImageView.heightAnchor.constraint(equalToConstant: 380),
            
            posterImageView.topAnchor.constraint(equalTo: backdropImageView.topAnchor),
            posterImageView.leadingAnchor.constraint(equalTo: backdropImageView.leadingAnchor),
            posterImageView.trailingAnchor.constraint(equalTo: backdropImageView.trailingAnchor),
            posterImageView.heightAnchor.constraint(equalTo: backdropImageView.heightAnchor),
            
            likeButton.topAnchor.constraint(equalTo: posterImageView.topAnchor, constant: 12),
            likeButton.trailingAnchor.constraint(equalTo: posterImageView.trailingAnchor, constant: -12),
            likeButton.widthAnchor.constraint(equalToConstant: 36),
            likeButton.heightAnchor.constraint(equalToConstant: 36),
            
            titleLabel.topAnchor.constraint(equalTo: posterImageView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            idLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            idLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            
            yearLabel.topAnchor.constraint(equalTo: idLabel.bottomAnchor, constant: 8),
            yearLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            
            ratingLabel.topAnchor.constraint(equalTo: yearLabel.bottomAnchor, constant: 8),
            ratingLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            
            overviewLabel.topAnchor.constraint(equalTo: ratingLabel.bottomAnchor, constant: 16),
            overviewLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            overviewLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            previewImagesCollectionView.topAnchor.constraint(equalTo: overviewLabel.bottomAnchor, constant: 20),
            previewImagesCollectionView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            previewImagesCollectionView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            previewImagesCollectionView.heightAnchor.constraint(equalToConstant: 80),
            
            showAllImagesButton.topAnchor.constraint(equalTo: previewImagesCollectionView.bottomAnchor, constant: 8),
            showAllImagesButton.trailingAnchor.constraint(equalTo: previewImagesCollectionView.trailingAnchor),
            showAllImagesButton.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupCloseButton() {
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Закрыть", for: .normal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    private func setupLikeButton() {
        likeButton.setTitle("♡ Like", for: .normal)
        likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
    }
    
    private func setupDoubleTapGesture() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        posterImageView.addGestureRecognizer(doubleTap)
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func likeButtonTapped() {
        guard let film = film else { return }
        try? realm.write {
            film.isLiked.toggle()
        }
        animateLikeButton()
        updateLikeButton()
        delegate?.didUpdateFilm(film)
    }
    
    @objc private func handleDoubleTap() {
        guard let film = film, let url = imageURL(for: film.testPic) else { return }
        let fullscreenVC = ImageFullscreenViewController()
        fullscreenVC.imageBaseURL = imageBaseURL
        fullscreenVC.posterSize = posterSize
        fullscreenVC.imageUrl = url
        fullscreenVC.modalPresentationStyle = .fullScreen
        present(fullscreenVC, animated: true)
    }
    
    @objc private func showAllImagesTapped() {
        guard let film = film else { return }
        let galleryVC = FullImageGalleryViewController()
        galleryVC.movieId = film.id
        galleryVC.modalPresentationStyle = .fullScreen
        present(galleryVC, animated: true)
    }

    
    private func configureWithFilm() {
        guard let film = film else { return }
        titleLabel.text = film.testTitle
        idLabel.text = "ID: \(film.id)"
        yearLabel.text = "Год: \(film.testYeah)"
        ratingLabel.text = "⭐️ \(film.testRating)/10"
        overviewLabel.text = film.testDescription
        
        if let url = imageURL(for: film.testPic) {
            loadImage(from: url, into: posterImageView)
            loadImage(from: url, into: backdropImageView)
        }
    }
    
    private func loadImage(from url: URL, into imageView: UIImageView) {
        if let cached = Self.imageCache.object(forKey: url.absoluteString as NSString) {
            imageView.image = cached
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            Self.imageCache.setObject(image, forKey: url.absoluteString as NSString)
            DispatchQueue.main.async {
                imageView.image = image
            }
        }.resume()
    }
    
    private func imageURL(for path: String) -> URL? {
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !trimmed.isEmpty else { return nil }
        return URL(string: "\(imageBaseURL)/\(posterSize)/\(trimmed)")
    }
    
    private func updateLikeButton() {
        guard let film = film else { return }
        let title = film.isLiked ? "♥️ Liked" : "♡ Like"
        likeButton.setTitle(title, for: .normal)
        likeButton.setTitleColor(film.isLiked ? .systemRed : .systemBlue, for: .normal)
    }
    
    private func animateLikeButton() {
        UIView.animate(withDuration: 0.2, animations: {
            self.likeButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                self.likeButton.transform = .identity
            }
        }
    }
    
    private func loadPreviewImages() {
        guard let id = film?.id else {
            print("❌ Нет ID фильма для загрузки изображений.")
            return
        }
        
        Task {
            do {
                // ✅ Используй API Key v3 (НЕ JWT-токен!)
                let apiKey = "ab376f359fcef3b2030735ceea2eeaf"
                let urlString = "https://api.themoviedb.org/3/movie/\(id)/images?api_key=\(apiKey)&language=ru-RU"
                guard let url = URL(string: urlString) else {
                    print("❌ Неверный URL: \(urlString)")
                    return
                }
                
                print("📡 Запрос изображений по URL: \(url)")
                
                let (data, response) = try await URLSession.shared.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📥 Статус-код ответа: \(httpResponse.statusCode)")
                    if httpResponse.statusCode != 200 {
                        print("❌ Ошибка сервера TMDb: \(httpResponse.statusCode)")
                    }
                }
                
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📄 Ответ JSON:\n\(jsonString)")
                }
                
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    print("❌ Невозможно разобрать JSON.")
                    return
                }
                
                let backdrops = (json["backdrops"] as? [[String: Any]]) ?? []
                self.previewImages = backdrops.prefix(3).compactMap { $0["file_path"] as? String }
                
                print("✅ Загружено превью: \(self.previewImages)")
                
                DispatchQueue.main.async {
                    self.previewImagesCollectionView.reloadData()
                }
                
            } catch {
                print("❌ Ошибка загрузки изображений: \(error.localizedDescription)")
            }
        }
    }
}
    
    extension DetailFilmViewController: UICollectionViewDataSource, UICollectionViewDelegate {
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return previewImages.count
        }
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PreviewImageCell.identifier, for: indexPath) as! PreviewImageCell
            let path = previewImages[indexPath.item]
            if let url = buildImageURL(baseURL: imageBaseURL, size: previewSize, path: path) {
                cell.configure(with: url)
            }
            return cell
        }
    }


extension DetailFilmViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionProfile = .show
        transition.start = start
        return transition
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionProfile = .pop
        transition.start = start
        return transition
    }
}
