//
//  Diary - ViewController.swift
//  Created by yagom. 
//  Copyright © yagom. All rights reserved.
// 

import UIKit

final class DiaryViewController: UIViewController {
    private var diaryData: [DiaryData] = []
    private var weather: Weather?
    private var dataSource: UITableViewDiffableDataSource<Section, DiaryData>?
    private var coreDataManager: CoreDataManager = CoreDataManager()
    private var networkManager: NetworkManager = NetworkManager()
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        getWeatherData()
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
        coreDataManager.create()
        diaryData = coreDataManager.fetch()
        let detailViewController = storyboard?.instantiateViewController(identifier: Identifiers.detalViewControllerID) as? DetailViewController ?? DetailViewController()
        detailViewController.diaryData = self.diaryData.last
        self.navigationController?.pushViewController(detailViewController, animated: true)
    }
    
    private func getWeatherData() {
        let urlComponenets = NetworkURL.weatherData(latitude: "10", longitude: "10")
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
