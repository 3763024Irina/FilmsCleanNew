import UIKit

class ImageFullscreenViewController: UIViewController {

    var image: UIImage?
    var startPoint: CGPoint = .zero

    private let imageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.frame = view.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(imageView)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
}
