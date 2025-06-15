import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)

        // Фильмы
        let mainVC = MainViewController()
        let mainNav = UINavigationController(rootViewController: mainVC)
        mainNav.tabBarItem = UITabBarItem(title: "Фильмы", image: UIImage(systemName: "film"), tag: 0)

        // Избранное
        let favoritesVC = FavoritesViewController()
        let favoritesNav = UINavigationController(rootViewController: favoritesVC)
        favoritesNav.tabBarItem = UITabBarItem(title: "Избранное", image: UIImage(systemName: "heart.fill"), tag: 1)

        // Tab Bar Controller
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [mainNav, favoritesNav]

        window.rootViewController = tabBarController
        self.window = window
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) { }
    func sceneDidBecomeActive(_ scene: UIScene) { }
    func sceneWillResignActive(_ scene: UIScene) { }
    func sceneWillEnterForeground(_ scene: UIScene) { }
    func sceneDidEnterBackground(_ scene: UIScene) { }
}
