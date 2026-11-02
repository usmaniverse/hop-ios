import XCTest
import HopCore
@testable import BookingFeature

private let home = Place(id: "home", name: "Home", coordinate: Coordinate(latitude: 0, longitude: 0))
private let office = Place(id: "office", name: "Office", coordinate: Coordinate(latitude: 0, longitude: 1))

@MainActor
final class BookingViewModelTests: XCTestCase {
    func testLoadsSavedPlaces() async {
        let sut = makeSUT(repository: StubRepository(places: [home, office]))

        await sut.loadPlaces()

        XCTAssertEqual(sut.places, .loaded([home, office]))
    }

    func testCannotConfirmUntilRouteIsValid() {
        let sut = makeSUT()
        XCTAssertFalse(sut.canConfirm)

        sut.pickup = home
        XCTAssertFalse(sut.canConfirm)

        sut.dropoff = home
        XCTAssertFalse(sut.canConfirm, "Pickup and drop-off must differ")

        sut.dropoff = office
        XCTAssertTrue(sut.canConfirm)
    }

    func testEstimateUsesInjectedEstimatorAndVehicleClass() {
        let sut = makeSUT()
        XCTAssertNil(sut.estimate)

        sut.pickup = home
        sut.dropoff = office
        sut.vehicleClass = .xl

        XCTAssertEqual(sut.estimate, Money(minorUnits: 3_000, currencyCode: "USD"))
    }

    func testConfirmBooksRideAndNotifiesCaller() async {
        var notified: Ride?
        let sut = makeSUT(onBooked: { notified = $0 })
        sut.pickup = home
        sut.dropoff = office

        await sut.confirm()

        guard case let .booked(ride) = sut.bookingState else {
            return XCTFail("Expected a booked state, got \(sut.bookingState)")
        }
        XCTAssertEqual(ride.pickup, home)
        XCTAssertEqual(ride.dropoff, office)
        XCTAssertEqual(notified, ride)
    }

    func testFailedBookingShowsErrorAndRecoversOnEdit() async {
        let sut = makeSUT(repository: StubRepository(bookingError: StubError()))
        sut.pickup = home
        sut.dropoff = office

        await sut.confirm()
        guard case .failed = sut.bookingState else {
            return XCTFail("Expected a failed state, got \(sut.bookingState)")
        }

        sut.vehicleClass = .comfort
        XCTAssertEqual(sut.bookingState, .editing)
    }

    func testStartOverClearsTheForm() async {
        let sut = makeSUT()
        sut.pickup = home
        sut.dropoff = office
        sut.vehicleClass = .xl
        await sut.confirm()

        sut.startOver()

        XCTAssertNil(sut.pickup)
        XCTAssertNil(sut.dropoff)
        XCTAssertEqual(sut.vehicleClass, .economy)
        XCTAssertEqual(sut.bookingState, .editing)
    }

    // MARK: - Helpers

    private func makeSUT(
        repository: StubRepository = StubRepository(),
        onBooked: @escaping @MainActor (Ride) -> Void = { _ in }
    ) -> BookingViewModel {
        BookingViewModel(repository: repository, estimator: FixedEstimator(), onBooked: onBooked)
    }
}

private struct StubError: Error {}

/// Returns 1,000 minor units per vehicle tier, so tests can assert exact values.
private struct FixedEstimator: FareEstimating {
    func estimate(from pickup: Place, to dropoff: Place, vehicleClass: VehicleClass) -> Money {
        let tier = VehicleClass.allCases.firstIndex(of: vehicleClass)! + 1
        return Money(minorUnits: tier * 1_000, currencyCode: "USD")
    }
}

private struct StubRepository: RideRepository {
    var places: [Place] = []
    var bookingError: (any Error & Sendable)?

    func rides() async throws -> [Ride] { [] }

    func savedPlaces() async throws -> [Place] { places }

    func book(_ request: BookingRequest) async throws -> Ride {
        if let bookingError { throw bookingError }
        return Ride(
            pickup: request.pickup,
            dropoff: request.dropoff,
            vehicleClass: request.vehicleClass,
            fare: Money(minorUnits: 1_000, currencyCode: "USD"),
            status: .scheduled,
            requestedAt: Date(timeIntervalSince1970: 0)
        )
    }
}
