//
//  Diary - ViewController.swift
//  Created by yagom. 
//  Copyright © yagom. All rights reserved.
// 

import UIKit
import CoreLocation

final class DiaryViewController: UIViewController {
    private var diaryData: [DiaryData] = []
    private var weather: Weather?
    private var dataSource: UITableViewDiffableDataSource<Section, DiaryData>?
    private var coreDataManager: CoreDataManager = CoreDataManager()
    private var networkManager: NetworkManager = NetworkManager()
    private var locationManager: CLLocationManager = CLLocationManager()
    private var location: Location?
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        view.addSubview(tableView)
        configureDataSource()
        configureSnapshot()
        setTableView()
        configureTableViewConstraint()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getDiaryData()
    }
    
    @IBAction func tapAddBarButtonItem(_ sender: UIBarButtonItem) {
        getWeatherData() // TODO: detailVC 처리로 변경
        coreDataManager.create()
        diaryData = coreDataManager.fetch()
        let detailViewController = storyboard?.instantiateViewController(identifier: Identifiers.detalViewControllerID) as? DetailViewController ?? DetailViewController()
        detailViewController.diaryData = self.diaryData.last
        self.navigationController?.pushViewController(detailViewController, animated: true)
    }
    
    private func getWeatherData() {
        guard let location = location else { return }
        let urlComponenets = NetworkURL.weatherData(latitude: location.latitude, longitude: location.longitude)
        guard let url = urlComponenets.url else { return }
        networkManager.requestData(url: url, type: OpenWeather.self) { data in
            switch data {
            case .success(let data):
                let weather = data.weather
                DispatchQueue.main.async {
                    self.weather = weather.first
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func getDiaryData() {
        diaryData = coreDataManager.fetch()
        self.configureSnapshot()
    }
    
    private func configureTableViewConstraint() {
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setTableView() {
        tableView.delegate = self
        tableView.register(UINib(nibName: String(describing: DiaryTableViewCell.self),
                                 bundle: nil),
                           forCellReuseIdentifier: Identifiers.diaryTableViewCellID)
    }
}

// MARK: - TableView Delegate
extension DiaryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let detailViewController: DetailViewController =
                storyboard?.instantiateViewController(withIdentifier: Identifiers.detalViewControllerID)
                as? DetailViewController else { return }
        detailViewController.setDiaryData(diaryData: diaryData[indexPath.row])
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}

// MARK: - TableView DataSource
extension DiaryViewController {
    private enum Section {
        case main
    }
    
    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource<Section, DiaryData>(tableView: tableView,
                                                   cellProvider: { tableView, indexPath, data in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.diaryTableViewCellID,
                                                           for: indexPath) as? DiaryTableViewCell
            else {
                return UITableViewCell()
            }
            cell.configureCell(data: data)
            
            return cell
        })
    }
    
    private func configureSnapshot() {
        var snapShot = NSDiffableDataSourceSnapshot<Section, DiaryData>()
        snapShot.appendSections([.main])
        snapShot.appendItems(diaryData)
        snapShot.reloadSections([.main])
        dataSource?.apply(snapShot, animatingDifferences: false)
    }
}

// MARK: - CLLocation Delegate

extension DiaryViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        let latitude = coordinate.latitude.description
        let longitude = coordinate.longitude.description
        print(latitude, longitude)
        location = Location(latitude: latitude, longitude: longitude)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkUserDivicesLocationAuthorization()
    }
    
    func checkUserDivicesLocationAuthorization() {
        DispatchQueue.global().async {
            guard CLLocationManager.locationServicesEnabled() else {
                self.locationSettingAlert()
                return
            }
        }
        
        // 2. 현재, 앱의 허용수준을 체크하여 허용수준에 따라 분기처리한다.
        let authorizaitonStatus: CLAuthorizationStatus
        authorizaitonStatus = locationManager.authorizationStatus
        handleAccordingToAuthorizationStatusLevel(authorizaitonStatus)
    }
    
    func handleAccordingToAuthorizationStatusLevel(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationSettingAlert()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        default:
            print("Default")
        }
    }
    
    private func locationSettingAlert() {
        let alert = UIAlertController(title: "위치를 설정해주세요.", message: "설정으로이동", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "네", style: .default) { action in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        }
        let noAction = UIAlertAction(title: "취소", style: .cancel)
        alert.addAction(okAction)
        alert.addAction(noAction)
        present(alert, animated: true)
    }
    
}
