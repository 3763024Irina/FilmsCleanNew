import UIKit

class FullPicViewController: UIViewController {
    private let imageView = UIImageView()

    /// Объект `ImageInfo`, содержащий путь и размер изображения
    var imageInfo: ImageInfo?

    override func viewDidLoad() {
        super.viewDidLoad()

        print("✅ Открыт FullPicViewController")
        view.backgroundColor = .black
        setupImageView()
        setupTapToDismiss()
        loadImage()
    }

    private func setupImageView() {
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupTapToDismiss() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closeTapped))
        tapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func closeTapped() {
        dismiss(animated: true, completion: nil)
    }

    private func loadImage() {
        guard let imageInfo = imageInfo else {
            print("❌ imageInfo не передан")
            return
        }

        ImageLoader.shared.loadImage(from: imageInfo.filePath, size: imageInfo.size.rawValue) { [weak self] image, error in
            if let error = error {
                print("❌ Ошибка загрузки: \(error.localizedDescription)")
                return
            }

            guard let image = image else {
                print("❌ Изображение не загружено")
                return
            }

            self?.imageView.image = image
        }
    }
}
