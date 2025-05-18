import UIKit
protocol MyCustomCellDelegate: AnyObject {
    func didDoubleTapPoster(for item: Item, startPoint: CGPoint)
    func didTapLikeButton(for item: Item)
}


class MyCustomCell: UICollectionViewCell {

    weak var delegate: MyCustomCellDelegate?
    private var currentItem: Item?

    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var filmTitleLabel: UILabel!
    @IBOutlet weak var releaseYearLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!

    private let idLabel = UILabel()
    private let likeButton = UIButton(type: .system)

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        setupGesture()
        setupIdLabel()
        setupLikeButton()
    }

    private func setupUI() {
        filmTitleLabel.numberOfLines = 0
        filmTitleLabel.lineBreakMode = .byWordWrapping
        filmTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        filmTitleLabel.textColor = .black

        releaseYearLabel.font = .systemFont(ofSize: 14)
        releaseYearLabel.textColor = .darkGray

        ratingLabel.font = .systemFont(ofSize: 14)
        ratingLabel.textColor = .systemBlue

        posterImageView.contentMode = .scaleAspectFill
        posterImageView.clipsToBounds = true
        posterImageView.layer.cornerRadius = 8
        posterImageView.isUserInteractionEnabled = true
    }

    private func setupIdLabel() {
        idLabel.font = .italicSystemFont(ofSize: 12)
        idLabel.textColor = .gray
        idLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(idLabel)

        NSLayoutConstraint.activate([
            idLabel.topAnchor.constraint(equalTo: filmTitleLabel.bottomAnchor, constant: 2),
            idLabel.leadingAnchor.constraint(equalTo: filmTitleLabel.leadingAnchor)
        ])
    }

    private func setupLikeButton() {
        likeButton.setTitle("♡", for: .normal)
        likeButton.titleLabel?.font = .systemFont(ofSize: 20)
        likeButton.tintColor = .systemBlue
        likeButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(likeButton)

        likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            likeButton.centerYAnchor.constraint(equalTo: ratingLabel.centerYAnchor),
            likeButton.leadingAnchor.constraint(equalTo: ratingLabel.trailingAnchor, constant: 20),
            likeButton.widthAnchor.constraint(equalToConstant: 30),
            likeButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func setupGesture() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        posterImageView.addGestureRecognizer(doubleTap)
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard let item = currentItem,
              let superview = posterImageView.superview else { return }

        let startPoint = superview.convert(posterImageView.center, to: nil)
        delegate?.didDoubleTapPoster(for: item, startPoint: startPoint)
    }


    @objc private func likeButtonTapped() {
        guard let item = currentItem else { return }
        delegate?.didTapLikeButton(for: item)
    }

    func configure(with item: Item, isImageOnly: Bool) {
        currentItem = item
        
        let image = UIImage(named: item.testPic ?? "") ?? UIImage(named: "placeholder")
        posterImageView.image = image

        filmTitleLabel.isHidden = isImageOnly
        releaseYearLabel.isHidden = isImageOnly
        ratingLabel.isHidden = isImageOnly
        idLabel.isHidden = isImageOnly
        likeButton.isHidden = isImageOnly

        if !isImageOnly {
            filmTitleLabel.text = item.testTitle ?? "-"
            releaseYearLabel.text = item.testYeah ?? "-"
            ratingLabel.text = "⭐️ \(item.testRating ?? "-")"
            idLabel.text = ""

            let likeTitle = item.isLiked ? "♥" : "♡"
            likeButton.setTitle(likeTitle, for: .normal)
            likeButton.tintColor = item.isLiked ? .systemRed : .systemBlue
        } else {
            filmTitleLabel.text = nil
            releaseYearLabel.text = nil
            ratingLabel.text = nil
            idLabel.text = nil
        }
    }
}
