import Combine
import Foundation
import NetworkExtension

struct Airport: Codable, Sendable {
    let iata, country, icao: String
    var city: String
    let latitude, longitude: Float
    let altitude: Double
    let tz: String

    enum CodingKeys: String, CodingKey {
        case city = "City"
        case country = "Country"
        case iata = "IATA"
        case icao = "ICAO"
        case latitude = "Latitude"
        case longitude = "Longitude"
        case altitude = "Altitude"
        case tz = "TZ"
    }
}

struct FlightInfo: Decodable {
    let timestamp: Date
    let eta: Double?
    let flightDuration: Int
    let flightNumber: String
    let latitude, longitude: Float
    let noseID: String?
    let paState: String? 
    let vehicleID, destination, origin: String
    let flightID: String?
    let airspeed, airTemperature, altitude, distanceToGo: Double?
    let doorState: String
    let groundspeed: Double
    let heading, timeToGo: Int
    let wheelWeightState: String
    
    var destinationAirport: Airport? = nil
    var originAirport: Airport? = nil
    
    enum CodingKeys: String, CodingKey {
        case timestamp, eta, flightDuration, flightNumber, latitude, longitude
        case noseID = "noseId"
        case paState
        case vehicleID = "vehicleId"
        case destination, origin
        case flightID = "flightId"
        case airspeed, airTemperature, altitude, distanceToGo, doorState, groundspeed, heading, timeToGo, wheelWeightState
    }
    
}

extension DateFormatter {
  static let iso8601Full: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
  }()
}

// MARK: - FlightInfo
struct LongerFlightInfo: Codable, Sendable {
    let response: Response

    enum CodingKeys: String, CodingKey {
        case response = "Response"
    }
    
    func transformInfoFlightInfo() -> FlightInfo {
        let flightInfo = response.flightInfo
        return FlightInfo(timestamp: flightInfo.utcTimeDate ?? Date.now, eta: nil, flightDuration: 0, flightNumber: flightInfo.flightNumberInfo, latitude: flightInfo.latitude, longitude: flightInfo.longitude, noseID: nil, paState: nil, vehicleID: flightInfo.tailNumber, destination: flightInfo.destinationAirportCode, origin: flightInfo.departureAirportCode, flightID: nil, airspeed: nil, airTemperature: 0, altitude: flightInfo.altitude, distanceToGo: 0, doorState: "", groundspeed: flightInfo.hspeed, heading: 0, timeToGo: response.systemInfo.timeToLand, wheelWeightState: "")
    }
}

// MARK: - Response
struct Response: Codable, Sendable {
    let status: Int
    let flightInfo: FlightInfoClass
    let gogoFacts: String
    let serviceInfo: ServiceInfo
    let ipAddress, macAddress: String
    let systemInfo: SystemInfo
    let deviceIid: String

    enum CodingKeys: String, CodingKey {
        case status, flightInfo, gogoFacts, serviceInfo, ipAddress, macAddress, systemInfo
        case deviceIid = "device_iid"
    }
}

// MARK: - FlightInfoClass
struct FlightInfoClass: Codable, Sendable {
    let logo, airlineName: String?
    let airlineCode: String
    let airlineCodeIata: String?
    let tailNumber, flightNumberInfo: String
    let flightNumberAlpha, flightNumberNumeric: String?
    let departureAirportCode, destinationAirportCode, departureAirportCodeIata, destinationAirportCodeIata: String
    let departureAirportLatitude, destinationAirportLatitude, departureAirportLongitude, destinationAirportLongitude: Double
    let origin, destination, departureCity, destinationCity: String?
    let expectedArrival: String
    let departureTime: String?
    let abpVersion, acpuVersion: String
    let videoService: Bool
    let latitude, longitude: Float
    let altitude: Double
    let localTime: String?
    let utcTime: String
    let destinationTimeZoneOffset: Int
    let hspeed, vspeed: Double
    
    var utcTimeDate: Date? {
        guard let utcTimeDate = DateFormatter.iso8601Full.date(from: utcTime) else {
            return nil
        }
        return utcTimeDate
    }
}

// MARK: - ServiceInfo
struct ServiceInfo: Codable, Sendable {
    let service: String
    let remaining: Int
    let quality, productCode: String?
    let alerts: [String]
}

// MARK: - SystemInfo
struct SystemInfo: Codable, Sendable {
    let wapType, systemType, arincEnabled: String
    let aboveGndLevel, aboveSeaLevel, flightPhase: String
    let horizontalVelocity, verticalVelocity: String
    let flightNo: String
    let timeToLand: Int
    let paxSSIDStatus, casSSIDStatus, countryCode, airportCode: String
    let linkState, linkType, tunnelState, tunnelType: String
    let ifcPaxServiceState, ifcCasServiceState, currentLinkStatusCode, currentLinkStatusDescription: String
    let noSubscribedUsers, aircraftType: String

    enum CodingKeys: String, CodingKey {
        case wapType, systemType, arincEnabled, horizontalVelocity, verticalVelocity, aboveGndLevel, aboveSeaLevel, flightPhase, flightNo, timeToLand
        case paxSSIDStatus = "paxSsidStatus"
        case casSSIDStatus = "casSsidStatus"
        case countryCode, airportCode, linkState, linkType, tunnelState, tunnelType, ifcPaxServiceState, ifcCasServiceState, currentLinkStatusCode, currentLinkStatusDescription, noSubscribedUsers, aircraftType
    }
}

enum InflightServiceError: Error {
    case wifiSSIDError
    case serviceDown
    case fetchFlightDataError
    case airportDataError
    
    var description: String {
        switch self {
        case .wifiSSIDError:
            return "Please ensure you are connected to inflight wifi"
        case .fetchFlightDataError:
            return "Error retrieving flight information, please refresh"
        case .serviceDown:
            return "Inflight Wifif Error, please refresh"
        case .airportDataError:
            return "Airport data was unable to be loaded"
        }
    }
}

class InflightService: ObservableObject {
    
    private var airports: [Airport] = []
    private var activeUrl: URL?
    private var session: URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30 // URL Session timeout
        return URLSession(configuration: configuration)
    }
    
    let validSSIDs = ["aainflight.com", "Test"]
    
    let urls = [
        URL(string: "https://kertob.americanplus.us/gtgn/flight1.php")!,
        URL(string: "https://kertob.americanplus.us/gtgn/flight2.php")!
    ]
    
    init() {
        loadAirports()
    }
    
    func checkForValidSSID() throws -> Bool {
        let wifiManager = WiFiManager()
        if let wifiSSID = wifiManager.getCurrentWiFiSSID(), validSSIDs.contains(wifiSSID) {
            return true
        } else {
            throw InflightServiceError.wifiSSIDError
        }
    }
    
    // load airport data from file
    private func loadAirports() {
        if let path = Bundle.main.path(forResource: "airports", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let decoder = JSONDecoder()
                airports = try decoder.decode([Airport].self, from: data)
                return
            } catch {
                print("Failed to load airport data: \(error.localizedDescription)")
            }
        } else {
            print("Could not find airports.json file")
        }
        airports = []
    }

    // check which URL is valid for FlightInfo data
    func checkForActiveUrl() async throws -> Bool {
        for url in urls {
            if let (_, response) = try? await session.data(from: url) {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    // valid url found
                    print("valid url found: \(url)")
                    activeUrl = url
                    return true
                }
            }
        }
        
        // if we go through all our URL's and no valid url is found, throw an error
        throw InflightServiceError.serviceDown
    }
    
    func fetchFlightInfo() async throws -> FlightInfo? {
        guard let activeUrl else { return nil }
        if airports.isEmpty {
            throw InflightServiceError.airportDataError
        }
        
        do {
            let (data, response) = try await session.data(from: activeUrl)
            
            // Check for 200 status code
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed to fetch data from: \(activeUrl.absoluteString)")
                throw InflightServiceError.fetchFlightDataError
            }
            
            // Decode the JSON data into FlightInfo
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            var flightInfo: FlightInfo
            
            // future TODO, add a swiftier way to hold both the urls in an easier to distinguish way
            if activeUrl.absoluteString.contains("flight1.php") {
                let longFlightInfo = try decoder.decode(LongerFlightInfo.self, from: data)
                // transform into FlightInfo
                flightInfo = longFlightInfo.transformInfoFlightInfo()
            } else {
                flightInfo = try decoder.decode(FlightInfo.self, from: data)
            }
            
            // configure airport data
            // not 100% to use ICAO vs IATA
            flightInfo.originAirport = airports.first(where: { $0.icao == flightInfo.origin })
            flightInfo.destinationAirport = airports.first(where: { ($0.icao == flightInfo.destination)})
            
            return flightInfo
        } catch {
            print("error: \(error.localizedDescription)")
            throw InflightServiceError.fetchFlightDataError
        }
    }
}
