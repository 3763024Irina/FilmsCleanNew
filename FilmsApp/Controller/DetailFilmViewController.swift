import UIKit
import RealmSwift

class DetailFilmViewController: UIViewController, UIViewControllerTransitioningDelegate {

    enum TransitionProfile {
        case show, pop
    }

    var transitionProfile: TransitionProfile = .show
    var start: CGPoint = .zero
    var transition = RoundingTransition()
    var cameFromFav: Bool = false

    var film: Item?

    private let posterImageView = UIImageView()
    private let titleLabel = UILabel()
    private let yearLabel = UILabel()
    private let ratingLabel = UILabel()
    private let backdropImageView = UIImageView()
    private let overviewLabel = UILabel()
    private let idLabel = UILabel()
    private let likeButton = UIButton(type: .system)

    private let realm = try! Realm()
    private static var imageCache = NSCache<NSString, UIImage>()

    private let imageBaseURL = "https://image.tmdb.org/t/p/"
    private let posterSize = "w500"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        transitioningDelegate = self
        transition.start = start

        setupUI()
        configureWithFilm()
        setupDoubleTapGesture()
        setupCloseButton()
        setupLikeButton()
    }

    private func setupCloseButton() {
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    @objc private func handleDoubleTap() {
        
        guard let film = film, !film.testPic.isEmpty else { return }
        let posterPath = film.testPic

        let fullVC = ImageFullscreenViewController()
        if let url = URL(string: "https://image.tmdb.org/t/p/w500/\(posterPath)") {
            // Если хотите передать URL напрямую:
            fullVC.imageUrl = url
        } else {
            // Если URL невалиден, передаем id и параметры для загрузки из Realm
            fullVC.itemId = film.id
            fullVC.imageBaseURL = imageBaseURL
            fullVC.posterSize = posterSize
        }
        fullVC.modalPresentationStyle = .fullScreen
        present(fullVC, animated: true)
    }



    private func setupUI() {
        [posterImageView, titleLabel, yearLabel, ratingLabel,
         backdropImageView, overviewLabel, idLabel, likeButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        titleLabel.font = .boldSystemFont(ofSize: 22)
        yearLabel.font = .systemFont(ofSize: 18)
        ratingLabel.font = .systemFont(ofSize: 18)
        overviewLabel.font = .systemFont(ofSize: 16)
        overviewLabel.numberOfLines = 0
        idLabel.font = .italicSystemFont(ofSize: 14)
        idLabel.textColor = .gray
        likeButton.titleLabel?.font = .systemFont(ofSize: 18)

        posterImageView.contentMode = .scaleAspectFill
        posterImageView.clipsToBounds = true
        posterImageView.isUserInteractionEnabled = true
        backdropImageView.contentMode = .scaleAspectFill
        backdropImageView.clipsToBounds = true

        NSLayoutConstraint.activate([
            posterImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            posterImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            posterImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            posterImageView.heightAnchor.constraint(equalToConstant: 250),

            titleLabel.topAnchor.constraint(equalTo: posterImageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            idLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            idLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            yearLabel.topAnchor.constraint(equalTo: idLabel.bottomAnchor, constant: 8),
            yearLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            ratingLabel.topAnchor.constraint(equalTo: yearLabel.bottomAnchor, constant: 8),
            ratingLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            likeButton.centerYAnchor.constraint(equalTo: ratingLabel.centerYAnchor),
            likeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            backdropImageView.topAnchor.constraint(equalTo: ratingLabel.bottomAnchor, constant: 16),
            backdropImageView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            backdropImageView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            backdropImageView.heightAnchor.constraint(equalToConstant: 120),

            overviewLabel.topAnchor.constraint(equalTo: backdropImageView.bottomAnchor, constant: 16),
            overviewLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            overviewLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            overviewLabel.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -16)
        ])
    }

    private func configureWithFilm() {
        guard let film = film else { return }
        
        titleLabel.text = film.testTitle
        idLabel.text = "ID: \(film.id)"
        yearLabel.text = "Год выпуска: \(film.testYeah)"
        ratingLabel.text = "Рейтинг: \(film.testRating)"
        overviewLabel.text = "Описание будет позже..."
        updateLikeButton()
        
        let path = film.testPic.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        guard !path.isEmpty else {
            posterImageView.image = UIImage(named: "placeholder")
            backdropImageView.image = UIImage(named: "placeholder")
            return
        }
        let urlString = "\(imageBaseURL)/\(posterSize)/\(path)"

        guard let url = URL(string: urlString) else {
            print("❌ Неверный URL: \(urlString)")
            posterImageView.image = UIImage(named: "placeholder")
            backdropImageView.image = UIImage(named: "placeholder")
            return
        }

        print("📸 URL: \(url.absoluteString)")
        loadImage(from: url, into: posterImageView)
        loadImage(from: url, into: backdropImageView)
    }



    private func loadImage(from url: URL, into imageView: UIImageView) {
        if let cachedImage = Self.imageCache.object(forKey: url.absoluteString as NSString) {
            imageView.image = cachedImage
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data,
                  let image = UIImage(data: data),
                  error == nil else {
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

    private func setupLikeButton() {
        likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
    }

    private func updateLikeButton() {
        guard let film = film else { return }
        let title = film.isLiked ? "♥️ Liked" : "♡ Like"
        likeButton.setTitle(title, for: .normal)
        likeButton.setTitleColor(film.isLiked ? .systemRed : .systemBlue, for: .normal)
    }

    @objc private func likeButtonTapped() {
        guard let film = film else { return }
        do {
            try realm.write {
                film.isLiked.toggle()
            }
            updateLikeButton()
        } catch {
            print("❌ Ошибка обновления like в Realm: \(error)")
        }
    }

    private func setupDoubleTapGesture() {
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        posterImageView.addGestureRecognizer(doubleTapGesture)
        posterImageView.isUserInteractionEnabled = true
    }


    // MARK: - Custom Transition
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionProfile = .show
        return transition
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionProfile = .pop
        return transition
    }
}
