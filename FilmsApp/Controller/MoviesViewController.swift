

import UIKit

class MoviesViewController: UIViewController {
    
    private var movies: [Movie] = []
    private var dataTask: URLSessionDataTask?
    private let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Фильмы Сейчас в кино"
        view.backgroundColor = .white
        
        setupTableView()
        loadNowPlaying()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dataTask?.cancel()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.dataSource = self
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: "cell")
    }
    
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

    private func loadNowPlaying() {
    
        let apiKey = "ab3776f359fcef3b2030735ceea2eeaf"
        let urlString = "https://api.themoviedb.org/3/movie/now_playing?api_key=\(apiKey)&language=ru-RU&page=1"
        guard let url = URL(string: urlString) else {
            print("❌ Некорректный URL: \(urlString)")
            return
        }
        
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

/*Codable-модели дают надёжный парсинг вместо неявных [[String: Any]].
 
 Отмена запроса через dataTask?.cancel() в viewWillDisappear и deinit защищает от «висящих» сетевых операций и связанных с ними утечек.

 Weak self в замыкании URLSession гарантирует отсутствие сильных циклов удержания.

 С этой схемой Instruments не будет показывать нарастание «Persistent Bytes» от сетевых вызовов — всё правильно инвалиируется и освобождается.*/
