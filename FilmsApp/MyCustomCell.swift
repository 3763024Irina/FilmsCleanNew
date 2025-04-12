import UIKit

class MyCustomCell: UICollectionViewCell {
    
    // Подключаем все элементы UI для ячейки
    private let filmTitleLabel = UILabel()
    private let releaseYearLabel = UILabel()
    private let ratingLabel = UILabel()
    private let posterImageView = UIImageView()
    
    struct MyModel {
        let filmTitle: String
        let releaseYeah: String
        let rating: String
        let posterPreview: String
        let isImageOnly: Bool
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Настроим элементы UI
        contentView.addSubview(filmTitleLabel)
        contentView.addSubview(releaseYearLabel)
        contentView.addSubview(ratingLabel)
        contentView.addSubview(posterImageView)
        
        setupConstraints() // Устанавливаем ограничения для элементов
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Функция для настройки ячейки с данными
    func configure(with model: MyModel) {
        filmTitleLabel.text = model.filmTitle
        releaseYearLabel.text = model.releaseYeah
        ratingLabel.text = model.rating
        
        // Если изображение существует, то отображаем его, иначе скрываем
        if !model.posterPreview.isEmpty {
            posterImageView.image = UIImage(named: model.posterPreview)
        } else {
            posterImageView.image = nil
        }
    }
    
    // Метод для настройки ограничений (если необходимо)
    private func setupConstraints() {
        // Отключаем автоматические констрейнты
        filmTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        releaseYearLabel.translatesAutoresizingMaskIntoConstraints = false
        ratingLabel.translatesAutoresizingMaskIntoConstraints = false
        posterImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Настройки для filmTitleLabel с возможностью переноса текста
        filmTitleLabel.numberOfLines = 0  // Позволяет переносу текста
        filmTitleLabel.lineBreakMode = .byWordWrapping
        filmTitleLabel.font = UIFont.systemFont(ofSize: 16) // Настроим шрифт для текста
        
        // Настройки для других элементов
        releaseYearLabel.font = UIFont.systemFont(ofSize: 14)
        ratingLabel.font = UIFont.systemFont(ofSize: 14)
        posterImageView.contentMode = .scaleAspectFill
        posterImageView.clipsToBounds = true // Картинка обрезается по границам
        
        // Используем UIStackView для вертикального расположения текста
        let stackView = UIStackView(arrangedSubviews: [filmTitleLabel, releaseYearLabel, ratingLabel])
        stackView.axis = .vertical
        stackView.spacing = 5
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stackView)
        
        // Настройки для констрейтов
        NSLayoutConstraint.activate([
            // StackView для текста
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: posterImageView.leadingAnchor, constant: -10),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            
            // Poster image view
            posterImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            posterImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            posterImageView.widthAnchor.constraint(equalToConstant: 100), // фиксированная ширина
            posterImageView.heightAnchor.constraint(equalToConstant: 150) // фиксированная высота
        ])
    }
}
