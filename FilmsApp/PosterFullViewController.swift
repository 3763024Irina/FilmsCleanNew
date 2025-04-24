import UIKit

class PosterFullViewController: UIViewController {

    var posterImageName: String?

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .black
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupImageView()
        setupGestures()

        if let imageName = posterImageName {
            imageView.image = UIImage(named: imageName)
        }
    }

    private func setupImageView() {
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupGestures() {
        // Двойной тап для закрытия
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dismissFullScreen))
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)

        // Pinch-to-zoom
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        imageView.addGestureRecognizer(pinch)
    }

    @objc private func dismissFullScreen() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let gestureView = gesture.view else { return }

        gestureView.transform = gestureView.transform.scaledBy(x: gesture.scale, y: gesture.scale)
        gesture.scale = 1.0

        // Ограничение масштаба
        if gesture.state == .ended {
            var currentScale = sqrt(gestureView.transform.a * gestureView.transform.a +
                                    gestureView.transform.c * gestureView.transform.c)

            currentScale = min(max(currentScale, 1.0), 3.0)

            UIView.animate(withDuration: 0.3) {
                gestureView.transform = CGAffineTransform(scaleX: currentScale, y: currentScale)
            }
        }
    }
}
