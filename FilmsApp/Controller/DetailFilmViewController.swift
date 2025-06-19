import UIKit
import RealmSwift

protocol DetailFilmViewControllerDelegate: AnyObject {
    func didUpdateFilm(_ film: Item)
}

class DetailFilmViewController: UIViewController {

    enum TransitionProfile {
        case show, pop, dismiss
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
            DispatchQueue.main.async { [weak self] in
                self?.configureWithFilm()
                self?.updateLikeButton()
                self?.loadPreviewImages()
                if let id = self?.film?.id {
                    self?.fetchTrailers(for: id) { trailers in
                        DispatchQueue.main.async {
                            self?.trailers = trailers
                            self?.trailersCollectionView.reloadData()
                        }
                    }
                }
            }
        }
    }

    var movieId: Int?
    var currentMovieId: Int?

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
    private var trailers: [Trailer] = []

    private let scrollView = UIScrollView()
    private let contentView = UIView()

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

    private let trailersCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        layout.itemSize = CGSize(width: 120, height: 80)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()

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
        setupScrollView()
        setupTransition()
        setupUI()
        setupCloseButton()
        setupLikeButton()
        setupDoubleTapGesture()

        trailersCollectionView.delegate = self
        trailersCollectionView.dataSource = self
        trailersCollectionView.register(TrailerCell.self, forCellWithReuseIdentifier: TrailerCell.identifier)

        previewImagesCollectionView.delegate = self
        previewImagesCollectionView.dataSource = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let id = film?.id {
            fetchTrailers(for: id) { [weak self] trailers in
                DispatchQueue.main.async {
                    self?.trailers = trailers
                    self?.trailersCollectionView.reloadData()
                }
            }
        }
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    private func setupTransition() {
        transition.start = start
        transition.transitionProfile = .show
        transitioningDelegate = self
        modalPresentationStyle = .custom
    }

    private func setupUI() {
        // Добавляем scrollView и contentView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Констрейнты scrollView
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Констрейнты contentView
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // Добавляем остальные элементы в contentView
        [
            backdropImageView, posterImageView, likeButton,
            titleLabel, idLabel, yearLabel, ratingLabel,
            overviewLabel, previewImagesCollectionView,
            showAllImagesButton, trailersCollectionView
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        // Стилизация элементов (оставляем без изменений)
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

        // Констрейнты для UI-элементов
        NSLayoutConstraint.activate([
            backdropImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            backdropImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            backdropImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
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
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),

            idLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            idLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            yearLabel.topAnchor.constraint(equalTo: idLabel.bottomAnchor, constant: 8),
            yearLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            ratingLabel.topAnchor.constraint(equalTo: yearLabel.bottomAnchor, constant: 8),
            ratingLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            overviewLabel.topAnchor.constraint(equalTo: ratingLabel.bottomAnchor, constant: 16),
            overviewLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            overviewLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            previewImagesCollectionView.topAnchor.constraint(equalTo: overviewLabel.bottomAnchor, constant: 12),
            previewImagesCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            previewImagesCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            previewImagesCollectionView.heightAnchor.constraint(equalToConstant: 80),

            showAllImagesButton.topAnchor.constraint(equalTo: previewImagesCollectionView.bottomAnchor, constant: 4),
            showAllImagesButton.trailingAnchor.constraint(equalTo: previewImagesCollectionView.trailingAnchor),

            trailersCollectionView.topAnchor.constraint(equalTo: showAllImagesButton.bottomAnchor, constant: 12),
            trailersCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            trailersCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            trailersCollectionView.heightAnchor.constraint(equalToConstant: 80),

            // ВАЖНО: Последний элемент замыкает scrollView
            trailersCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    private func setupCloseButton() {
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal) // ← иконка крестика
        closeButton.tintColor = .label // адаптивный цвет: черный/белый
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)


        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }


    private func setupLikeButton() {
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)
    }

    private func setupDoubleTapGesture() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(posterDoubleTapped))
        doubleTap.numberOfTapsRequired = 2
        posterImageView.addGestureRecognizer(doubleTap)
    }

    private func configureWithFilm() {
        guard let film = film else { return }
        titleLabel.text = film.testTitle
        idLabel.text = "ID: \(film.id)"
        yearLabel.text = film.testYeah
        ratingLabel.text = "Рейтинг: \(film.testRating)"
        overviewLabel.text = film.testDescription

        let posterURLString = "\(imageBaseURL)/\(posterSize)\(film.testPic)"
        loadImage(urlString: posterURLString, into: posterImageView)
        loadImage(urlString: posterURLString, into: backdropImageView)

        previewImages = Array(film.testPreviewPictures)
        previewImagesCollectionView.reloadData()
    }

    private func loadImage(urlString: String, into imageView: UIImageView) {
        if let cachedImage = DetailFilmViewController.imageCache.object(forKey: urlString as NSString) {
            imageView.image = cachedImage
            return
        }
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil,
                  let image = UIImage(data: data) else {
                return
            }
            DetailFilmViewController.imageCache.setObject(image, forKey: urlString as NSString)
            DispatchQueue.main.async {
                imageView.image = image
            }
        }.resume()
    }

    private func updateLikeButton() {
        let isLiked = film?.isLiked ?? false
        let imageName = isLiked ? "heart.fill" : "heart"
        likeButton.setImage(UIImage(systemName: imageName), for: .normal)
    }

    private func loadPreviewImages() {
        previewImagesCollectionView.reloadData()
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func likeTapped() {
        guard let film = film else { return }
        try! realm.write {
            film.isLiked.toggle()
            realm.add(film, update: .modified)
        }
        updateLikeButton()
        delegate?.didUpdateFilm(film)
    }

    @objc private func posterDoubleTapped() {
        guard let film = film,
              let _ = ImageLoader.shared.buildImageURL(from: film.posterPath, size: "original") else {
            print("❌ Некорректный путь к изображению")
            return
        }

        let fullScreenVC = FullPicViewController()
        fullScreenVC.modalPresentationStyle = .fullScreen
        let imageInfo = ImageInfo(filePath: film.posterPath ?? "", size: .original)
        fullScreenVC.imageInfo = imageInfo
        present(fullScreenVC, animated: true)
    }
    @objc private func showAllImagesTapped() {
        print("👆 showAllImagesTapped вызван")
        guard let id = film?.id else {
            print("❌ film.id не установлен")
            return
        }

        let galleryVC = FullImageGalleryViewController()
        galleryVC.movieId = id
        galleryVC.startingIndex = 0

        if let nav = navigationController {
            nav.pushViewController(galleryVC, animated: true)
        } else {
            print("❗️navigationController отсутствует, показываем модально")
            let navVC = UINavigationController(rootViewController: galleryVC)
            present(navVC, animated: true)
        }
    }

    func fetchTrailers(for movieId: Int, completion: @escaping ([Trailer]) -> Void) {
        let apiKey = "ab3776f359fcef3b2030735ceea2eeaf"
        let urlString = "https://api.themoviedb.org/3/movie/\(movieId)/videos?api_key=\(apiKey)&language=ru-RU"
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                completion([])
                return
            }
            do {
                let response = try JSONDecoder().decode(VideoResponse.self, from: data)
                let youtubeTrailers = response.results.filter { $0.site.lowercased() == "youtube" }
                completion(youtubeTrailers)
            } catch {
                print("❌ Ошибка парсинга трейлеров: \(error)")
                completion([])
            }
        }.resume()
    }
}

extension DetailFilmViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == trailersCollectionView {
            return trailers.count
        } else if collectionView == previewImagesCollectionView {
            return previewImages.count
        }
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == trailersCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrailerCell.identifier, for: indexPath) as? TrailerCell else {
                return UICollectionViewCell()
            }
            let trailer = trailers[indexPath.row]
            cell.configure(with: trailer)
            return cell
        } else if collectionView == previewImagesCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PreviewImageCell.identifier, for: indexPath) as? PreviewImageCell else {
                return UICollectionViewCell()
            }
            let imagePath = previewImages[indexPath.row]
            let fullURL = "\(imageBaseURL)/\(previewSize)\(imagePath)"
            cell.configure(with: fullURL)
            return cell
        }
        return UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == trailersCollectionView {
            let trailer = trailers[indexPath.row]
            if let url = URL(string: "https://www.youtube.com/watch?v=\(trailer.key)") {
                UIApplication.shared.open(url)
            }
        } else if collectionView == previewImagesCollectionView {
            let galleryVC = FullImageGalleryViewController()
            galleryVC.images = previewImages
            galleryVC.startingIndex = indexPath.row
            galleryVC.modalPresentationStyle = .fullScreen
            present(galleryVC, animated: true)
        }
    }
}

extension DetailFilmViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionProfile = .show
        return transition
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionProfile = .dismiss
        return transition
    }
}
