//
//  WeatherKitData.swift
//  BananaClock
//
//  Weather data model for WeatherKit integration
//

import Foundation

/// Weather data structure for WeatherKit integration
struct WeatherKitData: Codable, Sendable {
    let temperature: Double
    let condition: String
    let humidity: Double
    let windSpeed: Double
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case temperature
        case condition
        case humidity
        case windSpeed = "wind_speed"
        case description
    }
}