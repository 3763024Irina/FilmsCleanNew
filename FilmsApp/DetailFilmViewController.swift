import UIKit

class DetailFilmViewController: UIViewController {
    
    // MARK: - Public Properties
    var film: TestModel? // Модель фильма, передаётся извне
    
    // MARK: - UI Elements
    private let posterImageView = UIImageView()
    private let titleLabel = UILabel()
    private let yearLabel = UILabel()
    private let ratingLabel = UILabel()
    private let backdropImageView = UIImageView()
    private let overviewLabel = UILabel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        configureWithFilm()
        setupDoubleTapGesture()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        [posterImageView, titleLabel, yearLabel, ratingLabel, backdropImageView, overviewLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        titleLabel.font = .boldSystemFont(ofSize: 22)
        yearLabel.font = .systemFont(ofSize: 18)
        ratingLabel.font = .systemFont(ofSize: 18)
        overviewLabel.font = .systemFont(ofSize: 16)
        overviewLabel.numberOfLines = 0
        
        posterImageView.contentMode = .scaleAspectFill
        posterImageView.clipsToBounds = true
        posterImageView.isUserInteractionEnabled = true
        
        NSLayoutConstraint.activate([
            posterImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            posterImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            posterImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            posterImageView.heightAnchor.constraint(equalToConstant: 250),
            
            titleLabel.topAnchor.constraint(equalTo: posterImageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            yearLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            yearLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            
            ratingLabel.topAnchor.constraint(equalTo: yearLabel.bottomAnchor, constant: 8),
            ratingLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            
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
    
    // MARK: - Configure View
    private func configureWithFilm() {
        guard let film = film else { return }
        
        titleLabel.text = film.testTitle
        yearLabel.text = "Год выпуска: \(film.testYeah ?? "-")"
        ratingLabel.text = "Рейтинг: \(film.testRating ?? "-")"
        overviewLabel.text = "Описание будет позже..."
        
        if let posterName = film.testPic,
           let image = UIImage(named: posterName) {
            posterImageView.image = image
            backdropImageView.image = image
        }
    }
    
    // MARK: - Gesture
    private func setupDoubleTapGesture() {
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handlePosterDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        posterImageView.addGestureRecognizer(doubleTapGesture)
    }
    
    @objc private func handlePosterDoubleTap() {
        guard let image = posterImageView.image else { return }
        
        let fullImageVC = FullscreenImageViewController()
        fullImageVC.modalPresentationStyle = .fullScreen
        fullImageVC.image = image
        present(fullImageVC, animated: true)
    }
}
