import UIKit
import RealmSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

       
        let config = Realm.Configuration(
            schemaVersion: 4,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 4 {
                    migration.enumerateObjects(ofType: Item.className()) { oldObject, newObject in
                        if let oldTitle = oldObject?["testTitle"] as? String {
                            newObject?["testTitle"] = oldTitle
                        } else {
                            newObject?["testTitle"] = nil
                        }
                        if let oldYeah = oldObject?["testYeah"] as? String {
                            newObject?["testYeah"] = oldYeah
                        } else {
                            newObject?["testYeah"] = nil
                        }
                        if let oldRating = oldObject?["testRating"] as? String {
                            newObject?["testRating"] = oldRating
                        } else {
                            newObject?["testRating"] = nil
                        }
                        if let oldPic = oldObject?["testPic"] as? String {
                            newObject?["testPic"] = oldPic
                        } else {
                            newObject?["testPic"] = nil
                        }
                    }
                }
            }
        )

        Realm.Configuration.defaultConfiguration = config

        do {
            _ = try Realm()
            print("✅ Realm успешно инициализирован")
        } catch {
            print("❌ Ошибка инициализации Realm: \(error.localizedDescription)")
        }

        return true
    }

    // MARK: UISceneSession Lifecycle
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
