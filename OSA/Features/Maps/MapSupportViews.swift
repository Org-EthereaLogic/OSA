import CoreLocation
import SwiftUI

struct MapSectionCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            content
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.osaSurface, in: RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(.osaHairline, lineWidth: 1)
        }
    }
}

struct MapActionButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    let isDisabled: Bool
    let accessibilityLabel: String
    let accessibilityIdentifier: String
    let action: () -> Void

    init(
        title: String,
        systemImage: String,
        tint: Color = .osaPrimary,
        isDisabled: Bool = false,
        accessibilityLabel: String? = nil,
        accessibilityIdentifier: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.isDisabled = isDisabled
        self.accessibilityLabel = accessibilityLabel ?? title
        self.accessibilityIdentifier = accessibilityIdentifier ?? title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Image(systemName: systemImage)
                    .font(.headline)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            .padding(Spacing.md)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: CornerRadius.md))
            .foregroundStyle(tint)
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        }
        .disabled(isDisabled)
        .buttonStyle(.plain)
        .opacity(isDisabled ? 0.45 : 1)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(accessibilityIdentifier)
        .accessibilityRepresentation {
            Button(accessibilityLabel, action: action)
                .disabled(isDisabled)
                .accessibilityIdentifier(accessibilityIdentifier)
        }
    }
}

struct WaypointEditorSheet: View {
    let initialWaypoint: UserWaypoint?
    let coordinate: CLLocationCoordinate2D
    let onSave: (UserWaypoint) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var note = ""
    @State private var category: UserWaypointCategory = .general
    @State private var symbolName = ""

    var body: some View {
        Form {
            Section("Waypoint") {
                TextField("Title", text: $title)
                TextField("Note", text: $note, axis: .vertical)
                    .lineLimit(2...4)

                Picker("Category", selection: $category) {
                    ForEach(UserWaypointCategory.allCases) { category in
                        Label(category.title, systemImage: category.symbolName)
                            .tag(category)
                    }
                }

                TextField("Custom Symbol (Optional)", text: $symbolName)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section("Coordinate") {
                Text(RescueCoordinateFormatter.degreesDecimalMinutesString(from: coordinate))
                Text(RescueCoordinateFormatter.decimalDegreesString(from: coordinate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(initialWaypoint == nil ? "New Waypoint" : "Edit Waypoint")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    onSave(makeWaypoint())
                    dismiss()
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear {
            title = initialWaypoint?.title ?? ""
            note = initialWaypoint?.note ?? ""
            category = initialWaypoint?.category ?? .general
            symbolName = initialWaypoint?.symbolName ?? ""
        }
    }

    private func makeWaypoint() -> UserWaypoint {
        let existingID = initialWaypoint?.id ?? UUID()
        let createdAt = initialWaypoint?.createdAt ?? Date()

        return UserWaypoint(
            id: existingID,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note.trimmingCharacters(in: .whitespacesAndNewlines),
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            createdAt: createdAt,
            category: category,
            symbolName: symbolName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : symbolName.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}

struct OfflineRegionPlannerSheet: View {
    let region: MapRegion
    let budget: TileRegionBudget
    let planProvider: (String, ClosedRange<Int>) throws -> TileRegionSavePlan
    let onSave: (TileRegionSavePlan) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var lowerZoom = 11
    @State private var upperZoom = 13
    @State private var plan: TileRegionSavePlan?
    @State private var errorText: String?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Visible Region") {
                    Text(RescueCoordinateFormatter.degreesDecimalMinutesString(from: region.centerCoordinate))
                    Text("Span \(region.latitudeDelta.formatted(.number.precision(.fractionLength(2))))°, \(region.longitudeDelta.formatted(.number.precision(.fractionLength(2))))°")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Offline Save") {
                    TextField("Region Name", text: $name)

                    Stepper("Min Zoom: \(lowerZoom)", value: $lowerZoom, in: 8...16)
                    Stepper("Max Zoom: \(upperZoom)", value: $upperZoom, in: 9...17)
                }

                Section("Budget") {
                    Text("Max \(budget.maxTilesPerRegion) tiles per request")
                    Text(ByteCountFormatter.string(fromByteCount: budget.maxCacheSizeBytes, countStyle: .file) + " total cache")
                }

                if let errorText {
                    Section("Estimate") {
                        Text(errorText)
                            .foregroundStyle(.osaEmergency)
                    }
                }

                if let plan {
                    Section("Estimate") {
                        LabeledContent("Tiles", value: "\(plan.tileCount)")
                        LabeledContent("New Downloads", value: "\(plan.newTileCount)")
                        LabeledContent(
                            "Region Size",
                            value: ByteCountFormatter.string(fromByteCount: plan.estimatedSizeBytes, countStyle: .file)
                        )
                        LabeledContent(
                            "Projected Cache",
                            value: ByteCountFormatter.string(fromByteCount: plan.projectedCacheSizeBytes, countStyle: .file)
                        )
                    }
                }
            }
            .navigationTitle("Save Offline Region")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") {
                        guard let plan else { return }
                        isSaving = true
                        Task { @MainActor in
                            do {
                                try await onSave(plan)
                                dismiss()
                            } catch {
                                errorText = error.localizedDescription
                            }
                            isSaving = false
                        }
                    }
                    .disabled(plan == nil || isSaving)
                }
            }
            .onAppear(perform: refreshPlan)
            .onChange(of: name) { _, _ in refreshPlan() }
            .onChange(of: lowerZoom) { _, value in
                if value > upperZoom {
                    upperZoom = value
                }
                refreshPlan()
            }
            .onChange(of: upperZoom) { _, value in
                if value < lowerZoom {
                    lowerZoom = value
                }
                refreshPlan()
            }
        }
    }

    private func refreshPlan() {
        do {
            plan = try planProvider(name, lowerZoom...upperZoom)
            errorText = nil
        } catch {
            plan = nil
            errorText = error.localizedDescription
        }
    }
}

struct CompassUtilityView: View {
    let heading: HeadingReading?
    let isHeadingAvailable: Bool

    private var displayedHeading: Double? {
        heading?.displayHeading
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            if isHeadingAvailable, let displayedHeading {
                ZStack {
                    Circle()
                        .stroke(.osaHairline, lineWidth: 2)
                        .frame(width: 220, height: 220)

                    VStack {
                        Text("N")
                            .font(.headline)
                            .foregroundStyle(.osaEmergency)
                        Spacer()
                    }
                    .frame(height: 190)

                    Image(systemName: "location.north.line.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.osaPrimary)
                        .rotationEffect(.degrees(-displayedHeading))
                }

                Text("\(Int(displayedHeading.rounded()))° \(SunCompassCalculator.cardinalDirection(for: displayedHeading))")
                    .font(.title3.weight(.semibold))
            } else {
                ContentUnavailableView(
                    "Heading Unavailable",
                    systemImage: "location.slash",
                    description: Text("Compass heading usually requires a physical device. The map and sun compass still work offline.")
                )
            }
        }
        .padding(Spacing.xl)
        .navigationTitle("Compass")
        .navigationBarTitleDisplayMode(.inline)
        .background(.osaBackground)
    }
}

struct SunCompassUtilityView: View {
    let coordinate: CLLocationCoordinate2D?
    let date: Date

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if let coordinate,
                   let reading = SunCompassCalculator.reading(at: date, coordinate: coordinate) {
                    MapSectionCard(title: "Sun Compass", subtitle: "Approximate local reference") {
                        Text("\(Int(reading.azimuthDegrees.rounded()))° \(reading.cardinalDirection)")
                            .font(.title2.weight(.semibold))
                        Text(reading.guidance)
                            .font(.body)
                        Divider()
                        Text(RescueCoordinateFormatter.degreesDecimalMinutesString(from: coordinate))
                            .font(.subheadline)
                    }
                } else {
                    ContentUnavailableView(
                        "Sun Position Unavailable",
                        systemImage: "sun.max",
                        description: Text("Move the map or allow location access so OSA can estimate the sun’s azimuth for your current area.")
                    )
                }

                Text("Approximate field reference only. Terrain, season, weather, and time-zone drift can all affect practical accuracy.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(Spacing.lg)
        }
        .navigationTitle("Sun Compass")
        .navigationBarTitleDisplayMode(.inline)
        .background(.osaBackground)
    }
}
