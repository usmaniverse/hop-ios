import XCTest
import HopCore
@testable import HopData

final class FareCalculatorTests: XCTestCase {
    private let calculator = FareCalculator()

    func testShortTripIsChargedTheMinimumFare() {
        let fare = calculator.estimate(from: SampleData.home, to: SampleData.home, vehicleClass: .economy)
        XCTAssertEqual(fare.minorUnits, FareCalculator.Tariff.standard.minimumFare)
    }

    func testPremiumClassesCostMoreForTheSameRoute() {
        let economy = calculator.estimate(from: SampleData.home, to: SampleData.office, vehicleClass: .economy)
        let comfort = calculator.estimate(from: SampleData.home, to: SampleData.office, vehicleClass: .comfort)
        let xl = calculator.estimate(from: SampleData.home, to: SampleData.office, vehicleClass: .xl)

        XCTAssertLessThan(economy, comfort)
        XCTAssertLessThan(comfort, xl)
    }

    func testFareIsSymmetricForTheSameRoute() {
        let there = calculator.estimate(from: SampleData.home, to: SampleData.airport, vehicleClass: .economy)
        let back = calculator.estimate(from: SampleData.airport, to: SampleData.home, vehicleClass: .economy)
        XCTAssertEqual(there, back)
    }

    func testFareMatchesTariffForAKnownDistance() {
        // One degree of latitude is about 111.19 km.
        let a = Place(id: "a", name: "A", coordinate: Coordinate(latitude: 0, longitude: 0))
        let b = Place(id: "b", name: "B", coordinate: Coordinate(latitude: 1, longitude: 0))
        let tariff = FareCalculator.Tariff(
            baseFare: 100,
            perKilometre: 10,
            perMinute: 0,
            minimumFare: 0,
            averageSpeedKmh: 60,
            currencyCode: "USD"
        )

        let fare = FareCalculator(tariff: tariff).estimate(from: a, to: b, vehicleClass: .economy)

        // 100 + 10 * 111.19 = 1211.9, rounded to 1212.
        XCTAssertEqual(fare.minorUnits, 1212)
        XCTAssertEqual(fare.currencyCode, "USD")
    }

    func testHaversineDistanceForOneDegreeOfLatitude() {
        let distance = FareCalculator.distanceKilometres(
            Coordinate(latitude: 0, longitude: 0),
            Coordinate(latitude: 1, longitude: 0)
        )
        XCTAssertEqual(distance, 111.19, accuracy: 0.01)
    }
}

final class InMemoryRideRepositoryTests: XCTestCase {
    func testBookingAddsAScheduledRideToHistory() async throws {
        let fixedDate = Date(timeIntervalSince1970: 1_800_000_000)
        let repository = InMemoryRideRepository(rides: [], latency: .zero, now: { fixedDate })
        let request = BookingRequest(pickup: SampleData.home, dropoff: SampleData.gym, vehicleClass: .comfort)

        let booked = try await repository.book(request)
        let history = try await repository.rides()

        XCTAssertEqual(booked.status, .scheduled)
        XCTAssertEqual(booked.requestedAt, fixedDate)
        XCTAssertEqual(history, [booked])
    }

    func testRidesAreReturnedNewestFirst() async throws {
        let repository = InMemoryRideRepository(latency: .zero)
        let rides = try await repository.rides()
        XCTAssertEqual(rides.map(\.requestedAt), rides.map(\.requestedAt).sorted(by: >))
    }
}
