import SwiftUI
import HopCore
import HopDesignSystem

public struct RideHistoryView: View {
    @State private var viewModel: RideHistoryViewModel

    public init(viewModel: RideHistoryViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        content
            .navigationTitle("Your rides")
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Loading rides…")
        case let .failed(message):
            ContentUnavailableView {
                Label("Something went wrong", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try again") { Task { await viewModel.load() } }
            }
        case let .loaded(rides) where rides.isEmpty:
            ContentUnavailableView(
                "No rides yet",
                systemImage: "car",
                description: Text("Rides you book will show up here.")
            )
        case let .loaded(rides):
            List {
                if let total = viewModel.completedTotal {
                    Section {
                        LabeledContent("Spent on completed rides", value: total.formatted)
                    }
                }
                Section("History") {
                    ForEach(rides) { ride in
                        NavigationLink(value: ride) {
                            RideRow(ride: ride)
                        }
                    }
                }
            }
            .navigationDestination(for: Ride.self) { ride in
                RideDetailView(ride: ride)
            }
        }
    }
}

struct RideRow: View {
    let ride: Ride

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                RouteSummary(pickup: ride.pickup, dropoff: ride.dropoff)
                Text(ride.requestedAt, format: .dateTime.day().month().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text(ride.fare.formatted).font(.headline)
                StatusBadge(status: ride.status)
            }
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
    }
}

struct RideDetailView: View {
    let ride: Ride

    var body: some View {
        List {
            Section("Route") {
                RouteSummary(pickup: ride.pickup, dropoff: ride.dropoff)
            }
            Section("Details") {
                LabeledContent("Vehicle", value: ride.vehicleClass.displayName)
                LabeledContent("Fare", value: ride.fare.formatted)
                LabeledContent("Requested") {
                    Text(ride.requestedAt, format: .dateTime.day().month().year().hour().minute())
                }
                HStack {
                    Text("Status")
                    Spacer()
                    StatusBadge(status: ride.status)
                }
            }
        }
        .navigationTitle("Ride details")
    }
}
