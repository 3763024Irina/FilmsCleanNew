import UIKit

// Протокол делегата для MyCustomCell
protocol MyCustomCellDelegate: AnyObject {
    func didDoubleTapPoster(image: UIImage, startPoint: CGPoint)
}

class MyCustomCell: UICollectionViewCell {
    
    weak var delegate: MyCustomCellDelegate? // Делегат
    
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var filmTitleLabel: UILabel!
    @IBOutlet weak var releaseYearLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    
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
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard let image = posterImageView.image,
              let superview = posterImageView.superview else { return }
        
        let startPoint = superview.convert(posterImageView.center, to: nil)
        delegate?.didDoubleTapPoster(image: image, startPoint: startPoint)
    }
    
    func configure(with model: MyModel) {
        // Загрузка изображения с использованием переданного имени
        let image = UIImage(named: model.posterPreview) ?? UIImage(named: "placeholder")
        posterImageView.image = image
        
        // Если изображение только одно, скрываем текст
        let isTextHidden = model.isImageOnly
        filmTitleLabel.isHidden = isTextHidden
        releaseYearLabel.isHidden = isTextHidden
        ratingLabel.isHidden = isTextHidden
        
        // Если текст не скрыт, показываем данные
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

