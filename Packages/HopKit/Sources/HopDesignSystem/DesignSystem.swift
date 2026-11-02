import SwiftUI
import HopCore

/// Spacing tokens shared by every feature.
public enum Spacing {
    public static let xs: CGFloat = 4
    public static let s: CGFloat = 8
    public static let m: CGFloat = 16
    public static let l: CGFloat = 24
}

/// A status pill that pairs colour with text, so status is never conveyed by colour alone.
public struct StatusBadge: View {
    private let status: RideStatus

    public init(status: RideStatus) {
        self.status = status
    }

    public var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, Spacing.xs)
            .background(tint.opacity(0.15), in: Capsule())
            .foregroundStyle(tint)
            .accessibilityLabel("Status: \(title)")
    }

    private var title: String {
        switch status {
        case .scheduled: "Scheduled"
        case .completed: "Completed"
        case .cancelled: "Cancelled"
        }
    }

    private var tint: Color {
        switch status {
        case .scheduled: .blue
        case .completed: .green
        case .cancelled: .red
        }
    }
}

/// Full-width primary action with a built-in loading state.
public struct PrimaryButton: View {
    private let title: String
    private let isLoading: Bool
    private let action: @MainActor () -> Void

    public init(_ title: String, isLoading: Bool = false, action: @escaping @MainActor () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                Text(title).opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.s)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isLoading)
        .accessibilityLabel(isLoading ? "\(title), in progress" : title)
    }
}

/// A route summary used by both features.
public struct RouteSummary: View {
    private let pickup: Place
    private let dropoff: Place

    public init(pickup: Place, dropoff: Place) {
        self.pickup = pickup
        self.dropoff = dropoff
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Label(pickup.name, systemImage: "circle.fill")
            Label(dropoff.name, systemImage: "mappin.circle.fill")
        }
        .font(.subheadline)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("From \(pickup.name) to \(dropoff.name)")
    }
}
