import SwiftUI
import HopCore
import HopDesignSystem

public struct BookingView: View {
    @State private var viewModel: BookingViewModel

    public init(viewModel: BookingViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        Group {
            switch viewModel.places {
            case .idle, .loading:
                ProgressView("Loading places…")
            case let .failed(message):
                ContentUnavailableView(
                    "Places unavailable",
                    systemImage: "mappin.slash",
                    description: Text(message)
                )
            case let .loaded(places):
                if case let .booked(ride) = viewModel.bookingState {
                    BookedView(ride: ride, onDone: { viewModel.startOver() })
                } else {
                    form(places: places)
                }
            }
        }
        .navigationTitle("Book a ride")
        .task { await viewModel.loadPlaces() }
    }

    private func form(places: [Place]) -> some View {
        Form {
            Section("Route") {
                Picker("Pickup", selection: $viewModel.pickup) {
                    Text("Choose").tag(Place?.none)
                    ForEach(places) { Text($0.name).tag(Place?.some($0)) }
                }
                Picker("Drop-off", selection: $viewModel.dropoff) {
                    Text("Choose").tag(Place?.none)
                    ForEach(places) { Text($0.name).tag(Place?.some($0)) }
                }
                if viewModel.pickup != nil, viewModel.pickup == viewModel.dropoff {
                    Text("Pickup and drop-off must be different.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            Section("Vehicle") {
                Picker("Vehicle", selection: $viewModel.vehicleClass) {
                    ForEach(VehicleClass.allCases) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            if let estimate = viewModel.estimate {
                Section {
                    LabeledContent("Estimated fare", value: estimate.formatted)
                }
            }

            if case let .failed(message) = viewModel.bookingState {
                Section {
                    Text(message).foregroundStyle(.red)
                }
            }

            Section {
                PrimaryButton("Confirm ride", isLoading: viewModel.bookingState == .booking) {
                    Task { await viewModel.confirm() }
                }
                .disabled(!viewModel.canConfirm)
            }
        }
    }
}

private struct BookedView: View {
    let ride: Ride
    let onDone: @MainActor () -> Void

    var body: some View {
        VStack(spacing: Spacing.l) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
                .accessibilityHidden(true)
            Text("Ride booked").font(.title2.bold())
            RouteSummary(pickup: ride.pickup, dropoff: ride.dropoff)
            Text(ride.fare.formatted).font(.headline)
            PrimaryButton("Book another ride", action: onDone)
        }
        .padding(Spacing.l)
    }
}
