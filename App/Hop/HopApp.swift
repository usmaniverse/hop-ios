import SwiftUI
import HopCore
import HopData
import RideHistoryFeature
import BookingFeature

@main
struct HopApp: App {
    @State private var dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
        }
    }
}

/// The composition root: the only place that knows about concrete types.
/// Swapping the in-memory repository for a networked one happens here,
/// without touching any feature module.
@MainActor
final class AppDependencies {
    let repository: any RideRepository
    let estimator: any FareEstimating

    init(repository: any RideRepository, estimator: any FareEstimating) {
        self.repository = repository
        self.estimator = estimator
    }

    static func live() -> AppDependencies {
        let estimator = FareCalculator()
        return AppDependencies(
            repository: InMemoryRideRepository(estimator: estimator),
            estimator: estimator
        )
    }
}

struct RootView: View {
    enum Tab: Hashable { case book, history }

    let dependencies: AppDependencies

    @State private var selectedTab: Tab = .book
    @State private var historyID = UUID()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                BookingView(viewModel: BookingViewModel(
                    repository: dependencies.repository,
                    estimator: dependencies.estimator,
                    onBooked: { _ in historyID = UUID() }
                ))
            }
            .tabItem { Label("Book", systemImage: "car.fill") }
            .tag(Tab.book)

            NavigationStack {
                RideHistoryView(viewModel: RideHistoryViewModel(repository: dependencies.repository))
            }
            // A new identity reloads history after each booking.
            .id(historyID)
            .tabItem { Label("Rides", systemImage: "clock.arrow.circlepath") }
            .tag(Tab.history)
        }
    }
}
