import UIKit
class PosterFullscreenViewController: UIViewController {
    var image: UIImage?
    var startPoint: CGPoint = .zero

    private let imageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(origin: startPoint, size: CGSize(width: 0, height: 0)) // Начальная точка для анимации
        imageView.layer.cornerRadius = 15
        imageView.clipsToBounds = true
        view.addSubview(imageView)
        
        animateImage()  // Запускаем анимацию
    }

    private func animateImage() {
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut], animations: {
            self.imageView.frame = self.view.bounds // Увеличиваем изображение на весь экран
        })
    }
}
