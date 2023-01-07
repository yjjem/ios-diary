//
//  LocationManagerDelegate.swift
//  Diary
//
//  Copyright (c) 2023 woong, jeremy All rights reserved.


import Foundation
import CoreLocation

protocol Locateable {
    var manager: CLLocationManager { get }
    var desiredAccuracy: CLLocationAccuracy { get set }
    func startUpdating()
    func stopUpdating()
    func getLocation() -> String
    init()
}

struct LocationManager: Locateable {
    var lastLocation: Location?
    var manager: CLLocationManager = CLLocationManager()
    var desiredAccuracy: CLLocationAccuracy
    static var shared: Locateable = LocationManager()
    let delegate: LocationManagerDelegate = LocationManagerDelegate()
    
    init() {
        self.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = delegate
        manager.requestAlwaysAuthorization()
        startUpdating()
    }

    func getLocation() -> String {
        guard let location = manager.location else { return ""}
        let coordinates = location.coordinate
        stopUpdating()
        return "\(coordinates.latitude) and \( coordinates.longitude)"
    }
    
    func startUpdating() {
        manager.startUpdatingLocation()
    }
    
    func stopUpdating() {
        manager.stopUpdatingLocation()
    }
}

class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        let latitude = coordinate.latitude.description
        let longitude = coordinate.longitude.description
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        
        DispatchQueue.global().async {
            guard CLLocationManager.locationServicesEnabled() else {
                print("alert")
                return
            }
        }
        
        let authorizaitonStatus: CLAuthorizationStatus
        authorizaitonStatus = manager.authorizationStatus
        switch authorizaitonStatus {
        case .notDetermined:
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("alert")
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        default:
            print("Default")
        }
    }
}
