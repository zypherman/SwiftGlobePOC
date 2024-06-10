//
//  FlightInfoModel.swift
//  SwiftGlobe
//
//  Created by John Anderson on 6/8/24.
//  Copyright © 2024 David Mojdehi. All rights reserved.
//

import Foundation

@MainActor
class FlightInfoModel: ObservableObject {
    @Published var flightInfo: FlightInfo?
    @Published var serviceError: Error?
    
    @Published var timeAtOrigin: String = "N/A"
    @Published var originCity: String = "Origin"
    @Published var timeAtDestination: String = "N/A"
    @Published var destinationCity: String = "Destination"
    @Published var timeToGo: String = "N/A"
    @Published var groundSpeed: String = "N/A"
    @Published var altitude: String = "N/A"
    @Published var flightNumber: String = "N/A"
    
    private var timer: Timer?
    private var airports: [Airport] = []
    private var service = InflightService()
    
    init() {
        scheduleTimer()
    }
    
    private func scheduleTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            print("Starting HTTP poll for updated flight info")
            Task { @MainActor in
                await self.fetchFlightInfo()
            }
        }
    }
    
    func fetchFlightInfo() async {
        do {
            let info = try await service.fetchFlightInfo()
            await MainActor.run {
                flightInfo = info
                
                guard let flightInfo else { return }
                
                timeToGo = formatTimeToGo(flightInfo.timeToGo)
                
                if let originTimezone = flightInfo.originAirport?.tz {
                    timeAtOrigin = getCurrentTime(for: originTimezone)
                }
                
                if let destinationTimezone = flightInfo.destinationAirport?.tz {
                    timeAtDestination = getCurrentTime(for: destinationTimezone)
                }
                
                if let originAirportCity = flightInfo.originAirport?.city {
                    if let originCountry = flightInfo.originAirport?.country {
                        if originCountry != "US" {
                            originCity = "\(originAirportCity)\n\(originCountry)"
                        } else {
                            originCity = originAirportCity
                        }
                    }
                }
                
                if let destinationAirportCity = flightInfo.destinationAirport?.city {
                    if let originCountry = flightInfo.destinationAirport?.country {
                        if originCountry != "US" && originCountry != "United States" {
                            destinationCity = "\(destinationAirportCity)\n\(originCountry)"
                        } else {
                            destinationCity = destinationAirportCity
                        }
                    }
                }
                
                altitude = formatAltitude(flightInfo.altitude ?? 0)
                groundSpeed = "\(convertKnotsToMph(knots: flightInfo.groundspeed)) mph"
                flightNumber = flightInfo.flightNumber
            }
        } catch {
            print("There was an error retrieving the flight info")
            // Error handling here?
        }
    }
}

// Data formatters and calculations
extension FlightInfoModel {
    
    func formatCityCountry(city: String, country: String) -> String {
        return country == "United States" ? city : "\(city), \(country)"
    }
    
    func getCurrentTime(for timezone: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: timezone)
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: Date())
    }
    
    func formatTimeToGo(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        var result = ""
        
        if hours > 0 {
            result += "\(hours)h "
        }
        
        if remainingMinutes > 0 {
            result += "\(remainingMinutes)m"
        }
        
        return result.trimmingCharacters(in: .whitespaces)
    }
    
    func formatAltitude(_ altitude: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formattedAltitude = formatter.string(from: NSNumber(value: altitude)) ?? "\(Int(altitude))"
        return "\(formattedAltitude) ft"
    }
    
    func convertKnotsToMph(knots: Double) -> Int {
        return Int(knots * 1.15078)
    }
}
