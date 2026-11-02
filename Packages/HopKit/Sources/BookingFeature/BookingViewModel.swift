import Foundation
import Observation
import HopCore

@MainActor
@Observable
public final class BookingViewModel {
    public enum BookingState: Equatable {
        case editing
        case booking
        case booked(Ride)
        case failed(message: String)
    }

    public private(set) var places: Loadable<[Place]> = .idle
    public private(set) var bookingState: BookingState = .editing

    public var pickup: Place? = nil {
        didSet { resetAfterEdit() }
    }
    public var dropoff: Place? = nil {
        didSet { resetAfterEdit() }
    }
    public var vehicleClass: VehicleClass = .economy {
        didSet { resetAfterEdit() }
    }

    private let repository: any RideRepository
    private let estimator: any FareEstimating
    private let onBooked: @MainActor (Ride) -> Void

    public init(
        repository: any RideRepository,
        estimator: any FareEstimating,
        onBooked: @escaping @MainActor (Ride) -> Void = { _ in }
    ) {
        self.repository = repository
        self.estimator = estimator
        self.onBooked = onBooked
    }

    public func loadPlaces() async {
        guard case .idle = places else { return }
        places = .loading
        do {
            places = .loaded(try await repository.savedPlaces())
        } catch is CancellationError {
            places = .idle
        } catch {
            places = .failed(message: "Couldn't load your saved places.")
        }
    }

    /// A route is valid when both ends are chosen and they differ.
    public var hasValidRoute: Bool {
        guard let pickup, let dropoff else { return false }
        return pickup != dropoff
    }

    public var estimate: Money? {
        guard hasValidRoute, let pickup, let dropoff else { return nil }
        return estimator.estimate(from: pickup, to: dropoff, vehicleClass: vehicleClass)
    }

    public var canConfirm: Bool {
        hasValidRoute && bookingState != .booking
    }

    public func confirm() async {
        guard canConfirm, let pickup, let dropoff else { return }
        bookingState = .booking
        do {
            let ride = try await repository.book(
                BookingRequest(pickup: pickup, dropoff: dropoff, vehicleClass: vehicleClass)
            )
            bookingState = .booked(ride)
            onBooked(ride)
        } catch {
            bookingState = .failed(message: "We couldn't book this ride. Please try again.")
        }
    }

    public func startOver() {
        pickup = nil
        dropoff = nil
        vehicleClass = .economy
        bookingState = .editing
    }

    private func resetAfterEdit() {
        if case .failed = bookingState {
            bookingState = .editing
        }
    }
}
