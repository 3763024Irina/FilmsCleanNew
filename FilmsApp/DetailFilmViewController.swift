import UIKit

class DetailFilmViewController: UIViewController, UIViewControllerTransitioningDelegate {
    enum TransitionProfile {
        case show
        case pop
    }

    var transitionProfile: TransitionProfile = .show
    var start: CGPoint = .zero
    var transition = RoundingTransition()
    var film: TestModel?

    private let posterImageView = UIImageView()
    private let titleLabel = UILabel()
    private let yearLabel = UILabel()
    private let ratingLabel = UILabel()
    private let backdropImageView = UIImageView()
    private let overviewLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        transitioningDelegate = self
        transition.start = start // ← ВАЖНО!
        setupUI()
        configureWithFilm()
        setupDoubleTapGesture()
        setupCloseButton()
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

    private func setupDoubleTapGesture() {
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        posterImageView.addGestureRecognizer(doubleTapGesture)
    }

    @objc private func handleDoubleTap() {
        guard let posterImage = posterImageView.image else { return }

        let fullImageVC = FullscreenImageViewController()
        fullImageVC.image = posterImage
        fullImageVC.modalPresentationStyle = .fullScreen
        present(fullImageVC, animated: true)
    }

    // MARK: - Transitioning Delegate
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionProfile = .show
        return transition
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionProfile = .pop
        return transition
    }
}
