import UIKit

class TrailerCell: UICollectionViewCell {
    static let identifier = "TrailerCell"

    private let thumbnailImageView = UIImageView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.layer.cornerRadius = 8

        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            thumbnailImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 120),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 68),

            titleLabel.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with trailer: Trailer) {
        titleLabel.text = trailer.name

        guard let url = URL(string: "https://img.youtube.com/vi/\(trailer.key)/0.jpg") else {
            return
        }

        // Используем кеш
        if let cachedImage = ImageCache.shared.image(for: url) {
            thumbnailImageView.image = cachedImage
        } else {
            ImageCache.shared.loadImage(from: url) { [weak self] image in
                self?.thumbnailImageView.image = image
            }
        }
    }
}
