Ответы в дипломной работе:
Баг:

        // Как проявлялся баг здесь: раньше была такая структура:
    
/*
    dataTask = URLSession.shared.dataTask(with: url) { [weak self] data, resp, error in
        // …парсинг JSON…
        self?.movies = response.results
        self?.tableView.reloadData()    // ← ВЫЗОВ В ФОНОВОМ ПОТОКЕ
    }
    dataTask?.resume()
    Поскольку dataTask по-умолчанию работает в background queue, вызов reloadData() там:

    Может не обновить таблицу (UI не реагирует).

    Может крашнуть приложение с сообщением о попытке сменить UI вне главного потока.

    Исправление
    Обёрнули все изменения модели и перезагрузку UITableView в DispatchQueue.main.async
 Что это даёт
 Гарантия: все изменения, связанные с UIKit, происходят в главном потоке.

 Стабильность: исчезают «невидимые» баги с не обновляющимся UI или редкими крашами.

 Надёжность: можно быть уверенным, что tableView корректно перезагрузится сразу после получения данных.

 Таким образом мы устранили реальный баг с обновлением интерфейса в фоне — и теперь MoviesViewController работает предсказуемо и безопасно.

   */
/*Codable-модели дают надёжный парсинг вместо неявных [[String: Any]].
 
 Отмена запроса через dataTask?.cancel() в viewWillDisappear и deinit защищает от «висящих» сетевых операций и связанных с ними утечек.

 Weak self в замыкании URLSession гарантирует отсутствие сильных циклов удержания.

 С этой схемой Instruments не будет показывать нарастание «Persistent Bytes» от сетевых вызовов — всё правильно инвалиируется и освобождается.*/


Утечка памяти:

Типичные причины:

Сессии URLSession не инвалидируются и держат вложенные замыкания с сильными ссылками на self.

Нотификации / KVO: забыли отписаться от NotificationCenter/Realm notifications.

Timers: таймеры (DispatchSourceTimer, CADisplayLink) продолжают жить после ухода контроллера.

Realm: объекты-токены подписки (NotificationToken) не invalid().

Способ решения

В местах, где запускаются асинхронные работы (URLSession.dataTask, Realm observation, Timer), добавьте …{ [weak self] … } и инвалидировать/отписать в deinit или viewWillDisappear.

swift

После этих правок ещё раз профилирую Allocations + Leaks, чтобы убедиться, что «Persistent» аллокации не растут бесконечно.

Как убедиться, что утечка исправлена

Запустить с чистого старта Instruments, собрать пару циклов переходов между экранами.

Убедиться, что после закрытия экрана объём «Persistent» памяти возвращается примерно к исходному уровню.
    // Отменяем предыдущий запрос, если он ещё в работе была утечка памяти.
        dataTask?.cancel()
        
        dataTask = URLSession.shared.dataTask(with: url) { [weak self] data, resp, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Сетевая ошибка: \(error.localizedDescription)")
                return
            }
            
            guard let http = resp as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode) else {
                print("❌ Неверный HTTP-статус")
                return
            }
            
            guard let data = data else {
                print("❌ Данные не пришли")
                return
            }
            
            do {
                // Декодируем JSON в модель
                let response = try JSONDecoder().decode(MovieResponse.self,
                                                        from: data)
                DispatchQueue.main.async {
                    self.movies = response.results
                    self.tableView.reloadData()
                }
            } catch {
                print("❌ Ошибка парсинга: \(error)")
            }
        }
        dataTask?.resume()
    }
}

extension MoviesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        movies.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath)
                   -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell",
                                                 for: indexPath)
        let movie = movies[indexPath.row]
        cell.textLabel?.text = movie.title
        return cell
    }
}


 /* проблемы в реализации приложения:
 1. Проблема: RealmSwift подключается через CocoaPods как XCFramework, и его бинарники (по 60–100 МБ каждый) резко раздувают вес приложения и историю Git, из-за чего GitHub отказывается принимать пуши.
 Решение:

 Добавила папку Pods/ в .gitignore и выполнила git rm -r --cached Pods, чтобы исключить большие файлы из индекса.

 Перезаписала историю репозитория через git filter-branch (или BFG Repo-Cleaner), чтобы «очистить» прошлые коммиты от тяжёлых артефактов.

 
 Аргумент невозможности полного решения: без CocoaPods или без Realm нам бы пришлось отказываться от удобного ORM и работы с базой, поэтому проблемы веса лишь минимизируются, но не исчезают полностью.
 
 2. Настройка модульного тестирования (@testable import)
 Проблема: при попытке писать unit-тесты Xcode выдавал ошибку

 Module 'FilmsApp' was not compiled for testing
 — тесты не видели внутренние (internal) свойства приложения, потому что приложение собиралось без флага -enable-testing.
 Решение:

 В Build Settings таргета FilmsApp для конфигурации Debug включили Enable Testability = Yes.

 Перешла на рабочую область .xcworkspace, чтобы CocoaPods-схемы корректно подхватились.

 В схеме Edit Scheme → Test убедилась, что Build Configuration стоит Debug, и что оба таргета (FilmsApp и FilmsAppTests) участвуют в сборке и в тестах.
 Аргумент невозможности полного решения: без включения тестируемости нельзя использовать @testable import и покрывать код internal-методами, поэтому этот шаг обязателен для любых unit-тестов.

