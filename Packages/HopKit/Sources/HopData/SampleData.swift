import Foundation
import HopCore

/// Fictional places and rides for demos and previews.
/// Names are invented and do not refer to any real business or customer.
public enum SampleData {
    public static let home = Place(
        id: "home",
        name: "Home",
        coordinate: Coordinate(latitude: 31.5204, longitude: 74.3587)
    )
    public static let office = Place(
        id: "office",
        name: "Office",
        coordinate: Coordinate(latitude: 31.4697, longitude: 74.2728)
    )
    public static let gym = Place(
        id: "gym",
        name: "Gym",
        coordinate: Coordinate(latitude: 31.5497, longitude: 74.3436)
    )
    public static let airport = Place(
        id: "airport",
        name: "Airport",
        coordinate: Coordinate(latitude: 31.5216, longitude: 74.4036)
    )

    public static let places: [Place] = [home, office, gym, airport]

    public static var rides: [Ride] {
        let calculator = FareCalculator()
        let day: TimeInterval = 86_400
        let reference = Date(timeIntervalSince1970: 1_790_000_000)

        func ride(_ from: Place, _ to: Place, _ vehicle: VehicleClass, _ status: RideStatus, daysAgo: Double) -> Ride {
            Ride(
                pickup: from,
                dropoff: to,
                vehicleClass: vehicle,
                fare: calculator.estimate(from: from, to: to, vehicleClass: vehicle),
                status: status,
                requestedAt: reference.addingTimeInterval(-daysAgo * day)
            )
        }

        return [
            ride(home, office, .economy, .completed, daysAgo: 1),
            ride(office, gym, .comfort, .completed, daysAgo: 2),
            ride(home, airport, .xl, .cancelled, daysAgo: 5),
            ride(gym, home, .economy, .completed, daysAgo: 8),
        ]
    }
}
