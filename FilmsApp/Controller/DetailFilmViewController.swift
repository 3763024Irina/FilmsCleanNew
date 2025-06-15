import UIKit
import RealmSwift

protocol DetailFilmViewControllerDelegate: AnyObject {
    func didUpdateFilm(_ film: Item)
}

class DetailFilmViewController: UIViewController {
    
    enum TransitionProfile {
        case show, pop
    }
    
    // MARK: - Properties
    var item: Item? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.film = self?.item
            }
        }
    }
    
    var film: Item? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.configureWithFilm()
                self?.updateLikeButton()
            }
        }
    }
    
    var transitionProfile: TransitionProfile = .show
    var start: CGPoint = .zero
    var transition = RoundingTransition()
    var cameFromFav: Bool = false
    
    weak var delegate: DetailFilmViewControllerDelegate?
    
    private let realm: Realm = {
        do {
            return try Realm()
        } catch {
            fatalError("❌ Ошибка инициализации Realm: \(error)")
        }
    }()
    
    private static var imageCache = NSCache<NSString, UIImage>()
    private let imageBaseURL = "https://image.tmdb.org/t/p"
    private let posterSize = "w780"
    
    // MARK: - UI Elements
    
    private let posterImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.isUserInteractionEnabled = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let backdropImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.alpha = 0.4
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .boldSystemFont(ofSize: 22)
        lbl.textAlignment = .center
        lbl.numberOfLines = 2
        lbl.adjustsFontSizeToFitWidth = true
        lbl.minimumScaleFactor = 0.8
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let idLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .italicSystemFont(ofSize: 14)
        lbl.textColor = .gray
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let yearLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 18)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let ratingLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 18)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let overviewLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 16)
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let likeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.tintColor = .systemRed
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupTransition()
        setupUI()
        setupCloseButton()
        setupLikeButton()
        setupDoubleTapGesture()
        
        updateLikeButton()
        
        // Если film уже задан, загрузим данные на UI
        if let film = film {
            configureWithFilm()
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupTransition() {
        transition.start = start
        transition.transitionProfile = .show
        transition.onCompleted = { print("✅ Переход завершён (show)") }
        transition.onDismissed = { print("👈 Переход завершён (pop)") }
        
        transitioningDelegate = self
        modalPresentationStyle = .custom
    }
    
    private func setupUI() {
        view.addSubview(backdropImageView)
        let views = [posterImageView, titleLabel, idLabel, yearLabel, ratingLabel, overviewLabel, likeButton]
        views.forEach { view.addSubview($0) }
        
        NSLayoutConstraint.activate([
            backdropImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backdropImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backdropImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            backdropImageView.heightAnchor.constraint(equalToConstant: 380),
            
            posterImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            posterImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            posterImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            posterImageView.heightAnchor.constraint(equalToConstant: 380),
            
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
            overviewLabel.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupCloseButton() {
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
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
        likeButton.setTitleColor(.systemBlue, for: .normal)
        likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
    }
    
    private func setupDoubleTapGesture() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        posterImageView.addGestureRecognizer(doubleTap)
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func likeButtonTapped() {
        guard let film = film else { return }
        do {
            try realm.write {
                film.isLiked.toggle()
            }
            animateLikeButton()
            updateLikeButton()
            delegate?.didUpdateFilm(film)
        } catch {
            print("❌ Ошибка обновления like в Realm: \(error)")
        }
    }
    
    @objc private func handleDoubleTap() {
        guard let film = film, !film.testPic.isEmpty else { return }
        
        let fullscreenVC = ImageFullscreenViewController()
        fullscreenVC.imageBaseURL = imageBaseURL
        fullscreenVC.posterSize = posterSize
        
        if let url = imageURL(for: film.testPic) {
            fullscreenVC.imageUrl = url
        } else {
            fullscreenVC.itemId = film.id
        }
        
        fullscreenVC.modalPresentationStyle = .fullScreen
        present(fullscreenVC, animated: true)
    }
    
    // MARK: - Helper Methods
    
    private func configureWithFilm() {
        guard let film = film else {
            clearUI()
            return
        }
        
        // Заголовок
        titleLabel.text = film.testTitle.isEmpty ? "Без названия" : film.testTitle
        
        // ID
        idLabel.text = "ID: \(film.id)"
        
        // Год выпуска (если есть)
        yearLabel.text = film.testYeah.isEmpty ? "Год неизвестен" : "Год выпуска: \(film.testYeah)"
        
        // Рейтинг
        if let rating = Double(film.testRating), rating > 0 {
            ratingLabel.text = "⭐️ \(String(format: "%.1f", rating))/10"
            ratingLabel.textColor = .systemOrange
        } else {
            ratingLabel.text = "Нет рейтинга"
            ratingLabel.textColor = .secondaryLabel
        }
        
        // Описание (overview)
        if !film.testDescription.isEmpty {
            overviewLabel.text = film.testDescription
        } else {
            overviewLabel.text = "Описание будет позже..."
        }
        
        // Картинка постера и фон
        if let posterURL = imageURL(for: film.testPic) {
            loadImage(from: posterURL, into: posterImageView)
            loadImage(from: posterURL, into: backdropImageView)
        } else {
            setPlaceholderImages()
        }
        
        likeButton.isEnabled = true
    }
    
    private func clearUI() {
        titleLabel.text = "Нет данных"
        idLabel.text = ""
        yearLabel.text = "Год неизвестен"
        ratingLabel.text = "Нет рейтинга"
        overviewLabel.text = "Описание отсутствует"
        setPlaceholderImages()
        likeButton.isEnabled = false
    }
    
    private func setPlaceholderImages() {
        let placeholder = UIImage(named: "placeholder")
        posterImageView.image = placeholder
        backdropImageView.image = placeholder
    }
    
    private func imageURL(for path: String) -> URL? {
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !trimmed.isEmpty else { return nil }
        return URL(string: "\(imageBaseURL)/\(posterSize)/\(trimmed)")
    }
    
    private func loadImage(from url: URL, into imageView: UIImageView) {
        if let cachedImage = Self.imageCache.object(forKey: url.absoluteString as NSString) {
            DispatchQueue.main.async {
                imageView.image = cachedImage
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    imageView.image = UIImage(named: "placeholder")
                }
                return
            }
            
            Self.imageCache.setObject(image, forKey: url.absoluteString as NSString)
            DispatchQueue.main.async {
                imageView.image = image
            }
        }.resume()
    }
    
    private func updateLikeButton() {
        guard let film = film else {
            likeButton.setTitle("♡ Like", for: .normal)
            likeButton.setTitleColor(.systemBlue, for: .normal)
            likeButton.isEnabled = false
            return
        }
        
        let title = film.isLiked ? "♥️ Liked" : "♡ Like"
        let color = film.isLiked ? UIColor.systemRed : UIColor.systemBlue
        
        likeButton.setTitle(title, for: .normal)
        likeButton.setTitleColor(color, for: .normal)
        likeButton.isEnabled = true
    }
    
    private func animateLikeButton() {
        UIView.animate(withDuration: 0.2,
                       animations: { self.likeButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3) },
                       completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.likeButton.transform = .identity
            }
        })
    }
    
    // MARK: - Async loading full details (если нужно)
    func loadFullMovieDetails(movieId: Int) async {
        do {
            let fullDetails = try await fetchMovieDetailsFromAPI(movieId: movieId)
            // Обновляем модель и UI
            try realm.write {
                item?.testDescription = fullDetails.testDescription
                item?.testRating = fullDetails.testRating
                item?.testTitle = fullDetails.testTitle
                item?.testPic = fullDetails.testPic
                item?.testYeah = fullDetails.testYeah
            }
            DispatchQueue.main.async {
                self.film = self.item
                // Обновите UI здесь, если нужно
            }
        } catch {
            print("Ошибка загрузки деталей фильма: \(error)")
        }
    }
    
    // Новая функция для получения деталей фильма из TMDb API
    func fetchMovieDetailsFromAPI(movieId: Int) async throws -> Item {
        let apiKey = "ВАШ_API_КЛЮЧ"
        let urlString = "https://api.themoviedb.org/3/movie/\(movieId)?api_key=\(apiKey)&language=ru-RU"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "InvalidURL", code: 0, userInfo: nil)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard
            let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw NSError(domain: "ParsingError", code: 0, userInfo: nil)
        }
        
        let movieItem = Item()
        movieItem.update(from: jsonObject)
        movieItem.id = movieId
        
        return movieItem
    }
}
    // MARK: - UIViewControllerTransitioningDelegate
    
    extension DetailFilmViewController: UIViewControllerTransitioningDelegate {
        func animationController(forPresented presented: UIViewController,
                                 presenting: UIViewController,
                                 source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
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

