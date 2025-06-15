import Foundation
import UIKit

class PreviewImageCell: UICollectionViewCell {
    static let identifier = "PreviewImageCell"

    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 6
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Добавляем метод configure
    func configure(with url: URL) {
        // Очистим старое изображение (на случай повторного использования ячейки)
        imageView.image = nil
        
        // Простая загрузка изображения асинхронно через URLSession
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard
                let self = self,
                let data = data,
                let image = UIImage(data: data),
                error == nil
            else {
                return
            }
            DispatchQueue.main.async {
                self.imageView.image = image
            }
        }.resume()
    }
}
