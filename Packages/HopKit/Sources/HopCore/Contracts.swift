import Foundation

/// The data boundary features talk to. Features see only this protocol,
/// never a concrete network or storage type.
public protocol RideRepository: Sendable {
    func rides() async throws -> [Ride]
    func savedPlaces() async throws -> [Place]
    func book(_ request: BookingRequest) async throws -> Ride
}

/// Pure pricing logic, kept behind a protocol so features can be tested
/// with a fixed estimate.
public protocol FareEstimating: Sendable {
    func estimate(from pickup: Place, to dropoff: Place, vehicleClass: VehicleClass) -> Money
}

/// A simple async loading state shared by feature view models.
public enum Loadable<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(message: String)
}

extension Loadable: Equatable where Value: Equatable {}
extension Loadable: Sendable where Value: Sendable {}
