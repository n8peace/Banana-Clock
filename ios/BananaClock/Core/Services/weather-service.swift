//
//  WeatherService.swift
//  BananaClock
//
//  WeatherKit integration for location detection and weather data
//

import Foundation
import WeatherKit
import CoreLocation
import SwiftUI

@MainActor
class WeatherService: NSObject, ObservableObject {
    static let shared = WeatherService()
    
    private let weatherService = WeatherKit.WeatherService.shared
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var isRequestingLocation = false
    @Published var locationError: String?
    
    // Location data for user preferences
    @Published var detectedZipCode: String?
    @Published var detectedCity: String?
    @Published var detectedState: String?
    
    private override init() {
        super.init()
        locationManager.delegate = self
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Location Permissions & Detection
    
    /// Request location permission and detect current location
    func requestLocationAndDetect() async {
        await MainActor.run {
            isRequestingLocation = true
            locationError = nil
        }
        
        // Request permission if needed
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            // Wait for authorization callback
            return
        case .denied, .restricted:
            await MainActor.run {
                locationError = "Location permission denied. Please enable in Settings to auto-detect your location."
                isRequestingLocation = false
            }
            return
        case .authorizedWhenInUse, .authorizedAlways:
            // Permission granted, proceed with location detection
            break
        @unknown default:
            await MainActor.run {
                locationError = "Unknown location permission status"
                isRequestingLocation = false
            }
            return
        }
        
        // Request current location
        await detectCurrentLocation()
    }
    
    private func detectCurrentLocation() async {
        print("🔍 WeatherService: Requesting current location...")
        
        // Request one-time location
        locationManager.requestLocation()
        
        // Wait for location update (handled in delegate)
        // The delegate will call reverseGeocodeLocation when location is received
    }
    
    private func reverseGeocodeLocation(_ location: CLLocation) async {
        do {
            print("🔍 WeatherService: Reverse geocoding location...")
            
            // Using CLGeocoder for now - will migrate to MapKit when iOS 26 API is clarified
            #if compiler(>=6.0)
            #warning("CLGeocoder is deprecated in iOS 26 - migrate to MapKit when replacement API is documented")
            #endif
            
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            
            guard let placemark = placemarks.first else {
                await MainActor.run {
                    locationError = "Unable to determine address from location"
                    isRequestingLocation = false
                }
                return
            }
            
            await MainActor.run {
                // Extract location components
                detectedZipCode = placemark.postalCode
                detectedCity = placemark.locality
                detectedState = placemark.administrativeArea
                
                print("✅ WeatherService: Location detected:")
                print("  - City: \(detectedCity ?? "Unknown")")
                print("  - State: \(detectedState ?? "Unknown")")
                print("  - Zip: \(detectedZipCode ?? "Unknown")")
                
                isRequestingLocation = false
                locationError = nil
            }
            
        } catch {
            await MainActor.run {
                locationError = "Failed to get address: \(error.localizedDescription)"
                isRequestingLocation = false
            }
            print("❌ WeatherService: Reverse geocoding failed: \(error)")
        }
    }
    
    // MARK: - Weather Data (Future Implementation)
    
    /// Get current weather for a location
    func getCurrentWeather(for location: CLLocation) async throws -> WeatherData {
        print("🔍 WeatherService: Fetching weather for location...")
        
        let weather = try await weatherService.weather(for: location)
        
        return WeatherData(
            temperature: weather.currentWeather.temperature.value,
            condition: weather.currentWeather.condition.description,
            humidity: weather.currentWeather.humidity * 100,
            windSpeed: weather.currentWeather.wind.speed.value,
            description: weather.currentWeather.condition.description
        )
    }
    
    /// Clear detected location data
    func clearDetectedLocation() {
        detectedZipCode = nil
        detectedCity = nil
        detectedState = nil
        locationError = nil
    }
}

// MARK: - CLLocationManagerDelegate

extension WeatherService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        print("✅ WeatherService: Location received: \(location.coordinate)")
        
        Task { @MainActor in
            currentLocation = location
            
            // Reverse geocode the location to get address details
            await reverseGeocodeLocation(location)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ WeatherService: Location manager failed: \(error)")
        
        Task { @MainActor in
            locationError = "Failed to get location: \(error.localizedDescription)"
            isRequestingLocation = false
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("🔍 WeatherService: Authorization changed to: \(manager.authorizationStatus.rawValue)")
        
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            
            // If permission was just granted and we're in the middle of a request, continue
            if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
                if isRequestingLocation {
                    await detectCurrentLocation()
                }
            }
        }
    }
}