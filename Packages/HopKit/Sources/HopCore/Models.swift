import Foundation

public struct Coordinate: Hashable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct Place: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let coordinate: Coordinate

    public init(id: String, name: String, coordinate: Coordinate) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
    }
}

public enum VehicleClass: String, CaseIterable, Identifiable, Sendable {
    case economy
    case comfort
    case xl

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .economy: "Economy"
        case .comfort: "Comfort"
        case .xl: "XL"
        }
    }
}

public enum RideStatus: String, Sendable {
    case scheduled
    case completed
    case cancelled
}

/// Money stored in minor units (for example, cents) so arithmetic stays exact.
public struct Money: Hashable, Sendable, Comparable {
    public let minorUnits: Int
    public let currencyCode: String

    public init(minorUnits: Int, currencyCode: String) {
        self.minorUnits = minorUnits
        self.currencyCode = currencyCode
    }

    public var formatted: String {
        let amount = Decimal(minorUnits) / 100
        return amount.formatted(.currency(code: currencyCode))
    }

    public static func < (lhs: Money, rhs: Money) -> Bool {
        precondition(lhs.currencyCode == rhs.currencyCode, "Cannot compare different currencies")
        return lhs.minorUnits < rhs.minorUnits
    }
}

public struct Ride: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let pickup: Place
    public let dropoff: Place
    public let vehicleClass: VehicleClass
    public let fare: Money
    public let status: RideStatus
    public let requestedAt: Date

    public init(
        id: UUID = UUID(),
        pickup: Place,
        dropoff: Place,
        vehicleClass: VehicleClass,
        fare: Money,
        status: RideStatus,
        requestedAt: Date
    ) {
        self.id = id
        self.pickup = pickup
        self.dropoff = dropoff
        self.vehicleClass = vehicleClass
        self.fare = fare
        self.status = status
        self.requestedAt = requestedAt
    }
}

public struct BookingRequest: Hashable, Sendable {
    public let pickup: Place
    public let dropoff: Place
    public let vehicleClass: VehicleClass

    public init(pickup: Place, dropoff: Place, vehicleClass: VehicleClass) {
        self.pickup = pickup
        self.dropoff = dropoff
        self.vehicleClass = vehicleClass
    }
}
