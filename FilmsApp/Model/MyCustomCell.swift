import UIKit

// MARK: - Протокол делегата
protocol MyCustomCellDelegate: AnyObject {
    func didTapLikeButton(on cell: MyCustomCell)
    func didTapCell(_ cell: MyCustomCell)
}

class MyCustomCell: UICollectionViewCell {
    
    // MARK: - UI Elements
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.image = UIImage(named: "placeholder")
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 2
        lbl.textAlignment = .left
        lbl.adjustsFontSizeToFitWidth = true
        lbl.minimumScaleFactor = 0.8
        lbl.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let yearLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = .secondaryLabel
        lbl.font = UIFont.systemFont(ofSize: 14)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let ratingLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = .systemOrange
        lbl.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let likeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.tintColor = .systemRed
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    // MARK: - Properties
    
    weak var delegate: MyCustomCellDelegate?
    private var currentImagePath: String?
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGesture()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupGesture()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 12
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 4
        contentView.clipsToBounds = false
        
        likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        
        let ratingLikeStack = UIStackView(arrangedSubviews: [ratingLabel, likeButton])
        ratingLikeStack.axis = .horizontal
        ratingLikeStack.alignment = .center
        ratingLikeStack.spacing = 8
        
        let bottomStack = UIStackView(arrangedSubviews: [yearLabel, ratingLikeStack])
        bottomStack.axis = .horizontal
        bottomStack.alignment = .leading
        bottomStack.spacing = 16
        
        let infoStack = UIStackView(arrangedSubviews: [titleLabel, bottomStack])
        infoStack.axis = .vertical
        infoStack.alignment = .leading
        infoStack.spacing = 6
        
        let mainStack = UIStackView(arrangedSubviews: [imageView, infoStack])
        mainStack.axis = .vertical
        mainStack.alignment = .leading
        mainStack.spacing = 12
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 120),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1.5),
            
            likeButton.widthAnchor.constraint(equalToConstant: 30),
            likeButton.heightAnchor.constraint(equalToConstant: 30),
            
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            mainStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
        ])
    }
    
    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        contentView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Actions
    
    @objc private func likeButtonTapped() {
        animateLikeButton()
        delegate?.didTapLikeButton(on: self)
    }
    
    @objc private func cellTapped() {
        delegate?.didTapCell(self)
    }
    
    private func animateLikeButton() {
        UIView.animate(withDuration: 0.15, animations: {
            self.likeButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }) { _ in
            UIView.animate(withDuration: 0.15) {
                self.likeButton.transform = .identity
            }
        }
    }
    
    // MARK: - Configure
    
    func configure(with item: Item,
                   imageBaseURL: String = "https://image.tmdb.org/t/p",
                   posterSize: String = "w780") {
        
        titleLabel.text = item.testTitle.isEmpty ? "Без названия" : item.testTitle
        yearLabel.text = item.testYeah.isEmpty ? "Год неизвестен" : item.testYeah
        
        if let rating = Double(item.testRating), rating > 0 {
            ratingLabel.text = "⭐️ \(item.testRating)"
            ratingLabel.textColor = rating >= 7 ? .systemGreen : .systemOrange
        } else {
            ratingLabel.text = "Нет рейтинга"
            ratingLabel.textColor = .secondaryLabel
        }
        
        likeButton.setImage(
            UIImage(systemName: item.isLiked ? "heart.fill" : "heart"),
            for: .normal
        )
        
        let trimmedPath = item.testPic.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !trimmedPath.isEmpty else {
            imageView.image = UIImage(named: "placeholder")
            currentImagePath = nil
            return
        }
        
        // Собираем URL
        let fullPath: String
        if trimmedPath.hasPrefix(posterSize) {
            fullPath = "\(imageBaseURL)/\(trimmedPath)"
        } else {
            fullPath = "\(imageBaseURL)/\(posterSize)/\(trimmedPath)"
        }
        
        currentImagePath = fullPath
        imageView.image = UIImage(named: "placeholder")
        
        ImageLoader.shared.loadImage(from: fullPath) { [weak self] image, _ in
            guard let self = self else { return }
            guard self.currentImagePath == fullPath else { return } // защита от переиспользования
            if let image = image {
                UIView.transition(with: self.imageView,
                                  duration: 0.3,
                                  options: .transitionCrossDissolve,
                                  animations: {
                    self.imageView.image = image
                })
            }
        }
    }
}
