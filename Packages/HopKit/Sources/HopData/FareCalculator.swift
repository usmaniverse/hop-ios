import Foundation
import HopCore

/// Distance-and-time pricing with a per-class multiplier and a minimum fare.
/// All values are fictional and exist only to make the logic testable.
public struct FareCalculator: FareEstimating {
    public struct Tariff: Sendable {
        public var baseFare: Int          // minor units
        public var perKilometre: Int      // minor units
        public var perMinute: Int         // minor units
        public var minimumFare: Int       // minor units
        public var averageSpeedKmh: Double
        public var currencyCode: String

        public init(
            baseFare: Int,
            perKilometre: Int,
            perMinute: Int,
            minimumFare: Int,
            averageSpeedKmh: Double,
            currencyCode: String
        ) {
            self.baseFare = baseFare
            self.perKilometre = perKilometre
            self.perMinute = perMinute
            self.minimumFare = minimumFare
            self.averageSpeedKmh = averageSpeedKmh
            self.currencyCode = currencyCode
        }

        public static let standard = Tariff(
            baseFare: 250,
            perKilometre: 120,
            perMinute: 20,
            minimumFare: 500,
            averageSpeedKmh: 30,
            currencyCode: "USD"
        )
    }

    public let tariff: Tariff

    public init(tariff: Tariff = .standard) {
        self.tariff = tariff
    }

    public func estimate(from pickup: Place, to dropoff: Place, vehicleClass: VehicleClass) -> Money {
        let kilometres = Self.distanceKilometres(pickup.coordinate, dropoff.coordinate)
        let minutes = kilometres / tariff.averageSpeedKmh * 60

        let raw = Double(tariff.baseFare)
            + Double(tariff.perKilometre) * kilometres
            + Double(tariff.perMinute) * minutes
        let adjusted = raw * Self.multiplier(for: vehicleClass)
        let total = max(Int(adjusted.rounded()), tariff.minimumFare)

        return Money(minorUnits: total, currencyCode: tariff.currencyCode)
    }

    static func multiplier(for vehicleClass: VehicleClass) -> Double {
        switch vehicleClass {
        case .economy: 1.0
        case .comfort: 1.3
        case .xl: 1.6
        }
    }

    /// Great-circle distance using the haversine formula.
    static func distanceKilometres(_ a: Coordinate, _ b: Coordinate) -> Double {
        let earthRadiusKm = 6371.0
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let dLat = (b.latitude - a.latitude) * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180

        let h = sin(dLat / 2) * sin(dLat / 2)
            + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * earthRadiusKm * asin(min(1, sqrt(h)))
    }
}
