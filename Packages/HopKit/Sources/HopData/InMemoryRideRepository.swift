import Foundation
import HopCore

/// An in-memory repository with fictional sample data.
/// A networked implementation would conform to the same `RideRepository`
/// protocol, so no feature code would change.
public actor InMemoryRideRepository: RideRepository {
    private var storedRides: [Ride]
    private let places: [Place]
    private let estimator: any FareEstimating
    private let latency: Duration
    private let now: @Sendable () -> Date

    public init(
        rides: [Ride] = SampleData.rides,
        places: [Place] = SampleData.places,
        estimator: any FareEstimating = FareCalculator(),
        latency: Duration = .milliseconds(400),
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.storedRides = rides
        self.places = places
        self.estimator = estimator
        self.latency = latency
        self.now = now
    }

    public func rides() async throws -> [Ride] {
        try await Task.sleep(for: latency)
        return storedRides.sorted { $0.requestedAt > $1.requestedAt }
    }

    public func savedPlaces() async throws -> [Place] {
        try await Task.sleep(for: latency)
        return places
    }

    public func book(_ request: BookingRequest) async throws -> Ride {
        try await Task.sleep(for: latency)
        let ride = Ride(
            pickup: request.pickup,
            dropoff: request.dropoff,
            vehicleClass: request.vehicleClass,
            fare: estimator.estimate(
                from: request.pickup,
                to: request.dropoff,
                vehicleClass: request.vehicleClass
            ),
            status: .scheduled,
            requestedAt: now()
        )
        storedRides.append(ride)
        return ride
    }
}
