//
//  MainViewController.swift
//  Navigem
//
//  Created by Ryan The on 16/11/20.
//

import UIKit
import MapKit

class MainViewController: UIViewController {
    
    lazy var mapView = MKMapView()
    
    var locationManager: CLLocationManager {
        LocationProvider.shared.locationManager
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        self.view.backgroundColor = .systemBackground
                
        self.view = mapView
        locationManager.delegate = self
        mapView.delegate = self
        LocationProvider.shared.delegate = self
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func checkForUpdates() {
        
        let nowEpoch = Date().timeIntervalSince1970
        let lastOpenedEpoch = UserDefaults.standard.double(forKey: K.userDefaults.lastOpenedEpoch)
        let lastUpdatedEpoch = UserDefaults.standard.double(forKey: K.userDefaults.lastUpdatedEpoch)
        
        if lastOpenedEpoch == 0 {
            print("First Timer!")
            // First time using app
            let launchViewController = UIViewController()
            launchViewController.view.backgroundColor = .systemBackground
            launchViewController.isModalInPresentation = true
            self.present(launchViewController, animated: true)
        }
        
        if lastUpdatedEpoch+604800 < nowEpoch { // 1 week = 604800 seconds
            // Requires update of bus data
            print("Updating Bus Data...")
            ApiProvider.shared.updateBusData() {
                UserDefaults.standard.setValue(nowEpoch, forKey: K.userDefaults.lastUpdatedEpoch)
            }
        }
        
        UserDefaults.standard.setValue(nowEpoch, forKey: K.userDefaults.lastOpenedEpoch)
        
        // FIX: MAPPING CAUSING CRASH EXC_BAD_ACCESS
        //ApiProvider.shared.mapBusData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let homeSheetController = HomeSheetController()
        self.present(homeSheetController, animated: true, completion: nil)
        
        guard CLLocationManager.locationServicesEnabled() else {
            return
        }
        
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else {
            LocationProvider.shared.delegate?.locationProvider(didRequestNavigateToCurrentLocationWith: .one)
        }
        
        checkForUpdates()
    }
}

extension MainViewController: CLLocationManagerDelegate, MKMapViewDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        LocationProvider.shared.delegate?.locationProvider(didRequestNavigateToCurrentLocationWith: .one)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        fatalError(error.localizedDescription)
    }
}

extension MainViewController: LocationProviderDelegate {
    
    func locationProvider(didRequestNavigateTo location: CLLocation, with zoomLevel: ZoomLevel) {
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: zoomLevel.rawValue, longitudinalMeters: zoomLevel.rawValue)
        mapView.setRegion(region, animated: true)
    }
    
    func locationProvider(didRequestNavigateToCurrentLocationWith zoomLevel: ZoomLevel) {
        locationManager.requestLocation()
        let region = MKCoordinateRegion(center: LocationProvider.shared.currentLocation.coordinate, latitudinalMeters: zoomLevel.rawValue, longitudinalMeters: zoomLevel.rawValue)
        mapView.setRegion(region, animated: true)
    }

}
