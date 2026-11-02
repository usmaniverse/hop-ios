import Foundation
import Observation
import HopCore

@MainActor
@Observable
public final class RideHistoryViewModel {
    public private(set) var state: Loadable<[Ride]> = .idle

    private let repository: any RideRepository

    public init(repository: any RideRepository) {
        self.repository = repository
    }

    /// Loads rides. Safe to call again for pull-to-refresh.
    public func load() async {
        if case .idle = state {
            state = .loading
        }
        do {
            state = .loaded(try await repository.rides())
        } catch is CancellationError {
            // The view went away; keep whatever we had.
        } catch {
            state = .failed(message: "Couldn't load your rides. Please try again.")
        }
    }

    /// Total spent on completed rides, shown as a summary in the header.
    public var completedTotal: Money? {
        guard case let .loaded(rides) = state else { return nil }
        let completed = rides.filter { $0.status == .completed }
        guard let currency = completed.first?.fare.currencyCode else { return nil }
        let total = completed.reduce(0) { $0 + $1.fare.minorUnits }
        return Money(minorUnits: total, currencyCode: currency)
    }
}
