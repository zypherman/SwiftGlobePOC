import Combine
import Foundation

struct Airport: Codable, Sendable {
    let city, country, iata, icao: String // icao is the airport code
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
    let eta: Double? // unsure on this type
    let flightDuration: Int
    let flightNumber: String
    let latitude, longitude: Float
    let noseID: String
    let paState: String? // unsure on this type
    let vehicleID, destination, origin, flightID: String
    let airspeed, airTemperature, altitude, distanceToGo: Double
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

// MARK: - FlightInfo
struct LongerFlightInfo: Codable, Sendable {
    let response: Response

    enum CodingKeys: String, CodingKey {
        case response = "Response"
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
    let latitude, longitude, altitude: Double
    let localTime: String?
    let utcTime: String
    let destinationTimeZoneOffset: Int
    let hspeed, vspeed: Double
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
    let wapType, systemType, arincEnabled, horizontalVelocity: String
    let verticalVelocity, aboveGndLevel, aboveSeaLevel, flightPhase: String
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

class InflightService {
    
    enum InflightServiceError: Error {
        case fetchFlightDataError
        case requestError
    }
    
    private var airports: [Airport] = []
    private var activeUrl: URL?
    private var session: URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30 // URL Session timeout
        return URLSession(configuration: configuration)
    }
    
    let urls = [
//        URL(string: "https://kertob.americanplus.us/gtgn/flight1.php")!
        URL(string: "https://kertob.americanplus.us/gtgn/flight2.php")!
    ]
    
    init() {
        checkForActiveUrl()
        airports = loadAirports()
    }
    
    // load airport data from file
    private func loadAirports() -> [Airport] {
        if let path = Bundle.main.path(forResource: "airports", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let decoder = JSONDecoder()
                return try decoder.decode([Airport].self, from: data)
            } catch {
                print("Failed to load airport data: \(error.localizedDescription)")
            }
        } else {
            print("Could not find airports.json file")
        }
        return []
    }

    // check which URL is valid for FlightInfo data
    private func checkForActiveUrl() {
        Task {
            for url in urls {
                do {
                    let (_, response) = try await session.data(from: url)
                    
                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                        // valid url found
                        print("valid url found: \(url)")
                        activeUrl = url
                        break
                    }
                } catch {
                    print("error with request: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func fetchFlightInfo() async throws -> FlightInfo? {
        guard let activeUrl else { return nil }
        
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
            var flightInfo = try decoder.decode(FlightInfo.self, from: data)
            
            // configure airport data
            // not 100% to use ICAO vs IATA
            flightInfo.originAirport = airports.first(where: { $0.icao == flightInfo.origin })
            flightInfo.destinationAirport = airports.first(where: { $0.icao == flightInfo.destination })
            
            return flightInfo
        } catch {
            print("error: \(error.localizedDescription)")
            throw error
        }
    }
}