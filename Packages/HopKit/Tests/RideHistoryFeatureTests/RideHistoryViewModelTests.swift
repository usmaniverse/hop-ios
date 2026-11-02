import XCTest
import HopCore
@testable import RideHistoryFeature

@MainActor
final class RideHistoryViewModelTests: XCTestCase {
    func testLoadPublishesRides() async {
        let rides = [makeRide(fare: 1_000, status: .completed)]
        let sut = RideHistoryViewModel(repository: StubRepository(result: .success(rides)))

        await sut.load()

        XCTAssertEqual(sut.state, .loaded(rides))
    }

    func testLoadFailureShowsFriendlyMessage() async {
        let sut = RideHistoryViewModel(repository: StubRepository(result: .failure(StubError())))

        await sut.load()

        XCTAssertEqual(sut.state, .failed(message: "Couldn't load your rides. Please try again."))
    }

    func testCompletedTotalIgnoresCancelledAndScheduledRides() async {
        let rides = [
            makeRide(fare: 1_000, status: .completed),
            makeRide(fare: 2_500, status: .completed),
            makeRide(fare: 9_999, status: .cancelled),
            makeRide(fare: 7_777, status: .scheduled),
        ]
        let sut = RideHistoryViewModel(repository: StubRepository(result: .success(rides)))

        await sut.load()

        XCTAssertEqual(sut.completedTotal, Money(minorUnits: 3_500, currencyCode: "USD"))
    }

    func testCompletedTotalIsNilBeforeLoading() {
        let sut = RideHistoryViewModel(repository: StubRepository(result: .success([])))
        XCTAssertNil(sut.completedTotal)
    }

    // MARK: - Helpers

    private func makeRide(fare: Int, status: RideStatus) -> Ride {
        let place = Place(id: "p", name: "Place", coordinate: Coordinate(latitude: 0, longitude: 0))
        let other = Place(id: "q", name: "Other", coordinate: Coordinate(latitude: 0, longitude: 1))
        return Ride(
            pickup: place,
            dropoff: other,
            vehicleClass: .economy,
            fare: Money(minorUnits: fare, currencyCode: "USD"),
            status: status,
            requestedAt: Date(timeIntervalSince1970: 0)
        )
    }
}

private struct StubError: Error {}

private struct StubRepository: RideRepository {
    let result: Result<[Ride], StubError>

    func rides() async throws -> [Ride] { try result.get() }
    func savedPlaces() async throws -> [Place] { [] }
    func book(_ request: BookingRequest) async throws -> Ride { throw StubError() }
}
