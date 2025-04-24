import UIKit

protocol PosterTapDelegate: AnyObject {
    func didDoubleTapPoster(image: UIImage)
}

class MyCustomCell: UICollectionViewCell {
    
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var filmTitleLabel: UILabel!
    @IBOutlet weak var releaseYearLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    
    weak var delegate: PosterTapDelegate?

    struct MyModel {
        let filmTitle: String
        let releaseYeah: String
        let rating: String
        let posterPreview: String
        let isImageOnly: Bool
    }
    
    var onDoubleTap: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        setupGesture()
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

    private func setupGesture() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        posterImageView.addGestureRecognizer(doubleTap)
    }

    @objc private func handleDoubleTap() {
        if let onDoubleTap = onDoubleTap {
            onDoubleTap()
        } else if let image = posterImageView.image {
            delegate?.didDoubleTapPoster(image: image)
        }
    }

    func configure(with model: MyModel) {
        let image = UIImage(named: model.posterPreview) ?? UIImage(named: "placeholder")
        posterImageView.image = image
        
        let isTextHidden = model.isImageOnly
        filmTitleLabel.isHidden = isTextHidden
        releaseYearLabel.isHidden = isTextHidden
        ratingLabel.isHidden = isTextHidden

        if !isTextHidden {
            filmTitleLabel.text = model.filmTitle
            releaseYearLabel.text = model.releaseYeah
            ratingLabel.text = "⭐️ \(model.rating)"
        } else {
            filmTitleLabel.text = nil
            releaseYearLabel.text = nil
            ratingLabel.text = nil
        }
    }
}
