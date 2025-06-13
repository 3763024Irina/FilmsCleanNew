import UIKit

protocol MyCustomCellDelegate: AnyObject {
    func didTapLikeButton(on cell: MyCustomCell)
}

class MyCustomCell: UICollectionViewCell {
    
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let yearLabel = UILabel()
    private let ratingLabel = UILabel()
    private let likeButton = UIButton(type: .system)
    
    weak var delegate: MyCustomCellDelegate?

    private static var imageCache = NSCache<NSString, UIImage>()
    private var currentImageURL: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 12
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 4
        contentView.clipsToBounds = false

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = UIImage(named: "placeholder") // default

        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.numberOfLines = 2

        yearLabel.font = UIFont.systemFont(ofSize: 14)
        yearLabel.textColor = .darkGray

        ratingLabel.font = UIFont.systemFont(ofSize: 14)
        ratingLabel.textColor = .systemOrange

        likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
        likeButton.tintColor = .systemRed
        likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)

        let labelsStack = UIStackView(arrangedSubviews: [titleLabel, yearLabel, ratingLabel])
        labelsStack.axis = .vertical
        labelsStack.spacing = 4

        let mainStack = UIStackView(arrangedSubviews: [imageView, labelsStack, likeButton])
        mainStack.axis = .vertical
        mainStack.spacing = 8
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(mainStack)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.6),

            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    @objc private func likeButtonTapped() {
        delegate?.didTapLikeButton(on: self)
    }

    func configure(with item: Item, imageBaseURL: String, posterSize: String) {
        titleLabel.text = item.testTitle
        yearLabel.text = item.testYeah
        ratingLabel.text = item.testRating

        let isLiked = item.isLiked
        likeButton.setImage(UIImage(systemName: isLiked ? "heart.fill" : "heart"), for: .normal)

        let path = item.testPic
        guard !path.isEmpty else {
            imageView.image = UIImage(named: "placeholder")
            return
        }

        // Формирование корректного URL для изображения
        let baseURL = imageBaseURL.hasSuffix("/") ? imageBaseURL : imageBaseURL + "/"
        let sizePath = posterSize.hasSuffix("/") ? String(posterSize.dropLast()) : posterSize
        let fullPath = path.hasPrefix("/") ? String(path.dropFirst()) : path

        let fullURLString = baseURL + sizePath + "/" + fullPath
        currentImageURL = fullURLString
        print("📸 URL: \(fullURLString)")

        if let cachedImage = MyCustomCell.imageCache.object(forKey: fullURLString as NSString) {
            imageView.image = cachedImage
            return
        }

        imageView.image = UIImage(named: "placeholder") // пока загружается

        guard let url = URL(string: fullURLString) else {
            print("❌ Невалидный URL: \(fullURLString)")
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self,
                  let data = data,
                  let image = UIImage(data: data),
                  self.currentImageURL == fullURLString else {
                return
            }

            MyCustomCell.imageCache.setObject(image, forKey: fullURLString as NSString)
            DispatchQueue.main.async {
                self.imageView.image = image
            }
        }.resume()
    }
}
