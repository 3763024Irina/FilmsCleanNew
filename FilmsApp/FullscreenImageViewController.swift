import UIKit

class FullscreenImageViewController: UIViewController {
    
    var image: UIImage? // передаем готовое изображение
    
    private let imageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupImageView()
        setupCloseGesture()
    }

    private func setupImageView() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = image // устанавливаем изображение
        view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupCloseGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(closeFullscreen))
        view.addGestureRecognizer(tap)
    }

    @objc private func closeFullscreen() {
        dismiss(animated: true)
    }
}
