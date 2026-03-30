import CoreLocation
import MapKit
import SwiftUI
import UIKit

@MainActor
struct MapScreen: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.connectivityService) private var connectivityService
    @Environment(\.locationService) private var locationService
    @Environment(\.mapAnnotationProvider) private var annotationProvider
    @Environment(\.waypointRepository) private var waypointRepository
    @Environment(\.recordedTrackRepository) private var recordedTrackRepository
    @Environment(\.tileCacheService) private var tileCacheService
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService

    @State private var connectivity: ConnectivityState = .offline
    @State private var displayMode: MapDisplayMode = .online
    @State private var annotations: [MapAnnotationItem] = []
    @State private var waypoints: [UserWaypoint] = []
    @State private var tracks: [RecordedTrack] = []
    @State private var cachedRegions: [CachedTileRegion] = []
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var currentHeading: HeadingReading?
    @State private var selectedCategory: MapAnnotationCategory?
    @State private var visibleRegion: MapRegion = .defaultPNW
    @State private var coordinateFormat: CoordinateDisplayFormat = .degreesDecimalMinutes
    @State private var measurementPoints: [CLLocationCoordinate2D] = []
    @State private var sharePayload: ActivitySharePayload?
    @State private var showingWaypointEditor = false
    @State private var editingWaypoint: UserWaypoint?
    @State private var waypointDraftCoordinate: CLLocationCoordinate2D?
    @State private var showingOfflinePlanner = false
    @State private var showingCompass = false
    @State private var showingSunCompass = false
    @State private var actionError: String?
    @State private var recordingStartedAt: Date?
    @State private var recordingPaused = false
    @State private var recordingPauseReason: String?
    @State private var recordingSamples: [RecordedTrackPoint] = []
    @State private var locationAuthStatus: CLAuthorizationStatus = .notDetermined

    private let initialCategory: MapAnnotationCategory?

    init(initialCategory: MapAnnotationCategory? = nil) {
        self.initialCategory = initialCategory
        _selectedCategory = State(initialValue: initialCategory)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                categoryFilterBar
                mapContent
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)

                if displayMode != .online {
                    offlineBanner
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.md)
                }

                VStack(spacing: Spacing.lg) {
                    coordinateSummaryCard
                    quickActionsCard
                    trackRecordingCard
                    measurementCard
                    waypointSection
                    recordedTracksSection
                    cachedRegionsSection
                }
                .padding(Spacing.lg)
            }
        }
        .background(.osaBackground)
        .navigationTitle("Map")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if connectivity == .onlineUsable {
                        Button("Online Map", systemImage: "map") {
                            displayMode = .online
                        }
                    }

                    if !cachedRegions.isEmpty {
                        Button("Offline Tiles", systemImage: "map.fill") {
                            displayMode = .offlineCachedTiles
                        }
                    }

                    Button("Save Visible Offline Region", systemImage: "arrow.down.to.line") {
                        showingOfflinePlanner = true
                    }
                    .disabled(connectivity != .onlineUsable || tileCacheService == nil)

                    Button("Compass", systemImage: "location.north.circle") {
                        showingCompass = true
                    }

                    Button("Sun Compass", systemImage: "sun.max") {
                        showingSunCompass = true
                    }

                    Button("Open in Apple Maps", systemImage: "apple.logo") {
                        openInAppleMaps()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Map display options")
                .accessibilityHint("Shows offline save, compass, and display actions.")
            }
        }
        .sheet(item: $sharePayload) { payload in
            ActivityShareSheet(payload: payload)
        }
        .sheet(isPresented: $showingWaypointEditor) {
            NavigationStack {
                WaypointEditorSheet(
                    initialWaypoint: editingWaypoint,
                    coordinate: waypointDraftCoordinate ?? visibleRegion.centerCoordinate
                ) { waypoint in
                    saveWaypoint(waypoint)
                }
            }
        }
        .sheet(isPresented: $showingOfflinePlanner) {
            if let tileCacheService {
                OfflineRegionPlannerSheet(
                    region: visibleRegion,
                    budget: tileCacheService.regionBudget,
                    planProvider: { name, zoomRange in
                        try tileCacheService.planRegionSave(name: name, region: visibleRegion, zoomRange: zoomRange)
                    },
                    onSave: { plan in
                        _ = try await tileCacheService.saveRegion(using: plan)
                        loadCachedRegions()
                        if connectivity != .onlineUsable {
                            displayMode = .offlineCachedTiles
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showingCompass) {
            NavigationStack {
                CompassUtilityView(
                    heading: currentHeading,
                    isHeadingAvailable: locationService?.isHeadingAvailable ?? false
                )
            }
        }
        .sheet(isPresented: $showingSunCompass) {
            NavigationStack {
                SunCompassUtilityView(
                    coordinate: userLocation ?? visibleRegion.centerCoordinate,
                    date: Date()
                )
            }
        }
        .alert("Map Action", isPresented: actionErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(actionError ?? "")
        }
        .task { loadData() }
        .task { await observeConnectivity() }
        .task { await observeLocationSamples() }
        .task { await observeAuthorization() }
        .task { await observeHeading() }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase != .active, isRecording, !recordingPaused else { return }
            pauseRecording(reason: "Paused because OSA left the foreground.")
        }
    }

    private var mapContent: some View {
        Group {
            switch displayMode {
            case .online:
                OnlineMapView(
                    annotations: filteredAnnotations,
                    waypoints: waypoints,
                    measurementPoints: measurementPoints,
                    recordedTrackPoints: recordingSamples,
                    userLocation: userLocation,
                    visibleRegion: $visibleRegion
                )
            case .offlineCachedTiles:
                if let tileCacheService {
                    OfflineTileMapView(
                        annotations: filteredAnnotations,
                        waypoints: waypoints,
                        measurementPoints: measurementPoints,
                        recordedTrackPoints: recordingSamples,
                        tileCacheService: tileCacheService,
                        userLocation: userLocation,
                        visibleRegion: $visibleRegion
                    )
                } else {
                    offlineNoTilesView
                }
            case .offlineAppleMaps, .offlineNoTiles:
                offlineNoTilesView
            }
        }
        .background(.osaSurface)
    }

    private var coordinateSummaryCard: some View {
        MapSectionCard(
            title: "Coordinates",
            subtitle: "Rescue-friendly handoff defaults to DDM with decimal-degree copy support."
        ) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    ConnectivityBadge(state: connectivity)
                    Spacer()
                    Picker("Coordinate Format", selection: $coordinateFormat) {
                        ForEach(CoordinateDisplayFormat.allCases) { format in
                            Text(format.title).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 240)
                }

                coordinateLine(
                    label: "Current Location",
                    coordinate: userLocation,
                    fallbackText: locationAuthStatus == .notDetermined
                        ? "Tap below to allow location access."
                        : "Allow location access to relay your current position."
                )

                if userLocation == nil, locationAuthStatus == .notDetermined {
                    Button("Allow Location Access") {
                        locationService?.requestWhenInUseAuthorization()
                    }
                    .font(.subheadline)
                    .accessibilityLabel("Allow location access")
                    .accessibilityHint("Requests when-in-use location permission.")
                }

                coordinateLine(
                    label: "Map Center",
                    coordinate: visibleRegion.centerCoordinate,
                    fallbackText: "Move the map to update the center point."
                )
            }
        }
    }

    private var quickActionsCard: some View {
        MapSectionCard(title: "Quick Actions", subtitle: "Bounded local tools from the current map view.") {
            VStack(spacing: Spacing.md) {
                HStack(spacing: Spacing.md) {
                    MapActionButton(
                        title: "Save Visible Waypoint",
                        systemImage: "mappin.and.ellipse",
                        accessibilityLabel: "Save visible waypoint",
                        accessibilityIdentifier: "Save visible waypoint"
                    ) {
                        beginWaypointCreation(at: visibleRegion.centerCoordinate)
                    }

                    MapActionButton(
                        title: "Save Offline Region",
                        systemImage: "arrow.down.to.line",
                        tint: .osaTrust,
                        isDisabled: connectivity != .onlineUsable || tileCacheService == nil,
                        accessibilityIdentifier: "Save offline region"
                    ) {
                        showingOfflinePlanner = true
                    }
                }

                HStack(spacing: Spacing.md) {
                    MapActionButton(
                        title: "Compass",
                        systemImage: "location.north.circle",
                        tint: .osaPrimary,
                        accessibilityIdentifier: "Open compass"
                    ) {
                        showingCompass = true
                    }

                    MapActionButton(
                        title: "Sun Compass",
                        systemImage: "sun.max",
                        tint: .osaWarning,
                        accessibilityIdentifier: "Open sun compass"
                    ) {
                        showingSunCompass = true
                    }
                }
            }
        }
    }

    private var trackRecordingCard: some View {
        MapSectionCard(
            title: "Track Recording",
            subtitle: "Foreground-only. Recording pauses when the app backgrounds or location access changes."
        ) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(trackStatusText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if isRecording {
                    LabeledContent(
                        "Points",
                        value: "\(recordingSamples.count)"
                    )
                    LabeledContent(
                        "Distance",
                        value: NavigationDistanceCalculator.formattedDistance(
                            NavigationDistanceCalculator.cumulativeDistance(for: recordingSamples)
                        )
                    )
                }

                HStack(spacing: Spacing.md) {
                    if !isRecording {
                        Button("Start Track") {
                            startRecording()
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel("Start track recording")
                    } else if recordingPaused {
                        Button("Resume") {
                            resumeRecording()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Stop") {
                            stopRecording()
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button("Pause") {
                            pauseRecording(reason: "Paused by user.")
                        }
                        .buttonStyle(.bordered)

                        Button("Stop") {
                            stopRecording()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }

    private var measurementCard: some View {
        MapSectionCard(title: "Distance Measurement", subtitle: "Drop points from the map center or your current location.") {
            VStack(alignment: .leading, spacing: Spacing.md) {
                LabeledContent("Points", value: "\(measurementPoints.count)")
                LabeledContent(
                    "Cumulative Distance",
                    value: NavigationDistanceCalculator.formattedDistance(
                        NavigationDistanceCalculator.cumulativeDistance(for: measurementPoints)
                    )
                )

                HStack(spacing: Spacing.md) {
                    Button("Add Center Point") {
                        measurementPoints.append(visibleRegion.centerCoordinate)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Add center point")

                    Button("Add My Location") {
                        if let userLocation {
                            measurementPoints.append(userLocation)
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(userLocation == nil)

                    Spacer()

                    Button("Reset") {
                        measurementPoints.removeAll()
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.osaEmergency)
                }
            }
        }
    }

    private var waypointSection: some View {
        MapSectionCard(title: "Waypoints", subtitle: "Stored locally and rendered on the map in both live and cached tile modes.") {
            if waypoints.isEmpty {
                Text("No saved waypoints yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: Spacing.md) {
                    ForEach(waypoints) { waypoint in
                        waypointRow(waypoint)
                    }
                }
            }
        }
    }

    private var recordedTracksSection: some View {
        MapSectionCard(title: "Recorded Tracks", subtitle: "Finished tracks persist locally and can export as GPX.") {
            if tracks.isEmpty {
                Text("No recorded tracks yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: Spacing.md) {
                    ForEach(tracks) { track in
                        trackRow(track)
                    }
                }
            }
        }
    }

    private var cachedRegionsSection: some View {
        MapSectionCard(title: "Offline Regions", subtitle: "Bounded OSM tile downloads with explicit storage limits.") {
            if cachedRegions.isEmpty {
                Text("No offline regions saved yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: Spacing.md) {
                    ForEach(cachedRegions) { region in
                        cachedRegionRow(region)
                    }
                }
            }
        }
    }

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                FilterChip(title: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(MapAnnotationCategory.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.rawValue.capitalized,
                        isSelected: selectedCategory == category,
                        icon: category.icon
                    ) {
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
        }
        .background(Color.osaSurface)
    }

    private var filteredAnnotations: [MapAnnotationItem] {
        guard let selectedCategory else { return annotations }
        return annotations.filter { $0.category == selectedCategory }
    }

    private var offlineBanner: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "wifi.slash")
                .font(.caption)
            Text("Showing local-only map data")
                .font(.caption.weight(.medium))
            Spacer()
            Button("Open Apple Maps") {
                openInAppleMaps()
            }
            .font(.caption.weight(.medium))
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(Color.osaWarning.opacity(0.12), in: RoundedRectangle(cornerRadius: CornerRadius.md))
        .foregroundStyle(.osaWarning)
    }

    private var offlineNoTilesView: some View {
        ContentUnavailableView(
            "No Cached Tiles",
            systemImage: "map",
            description: Text("Save a visible region while online to make this map area available offline.")
        )
    }

    private var actionErrorBinding: Binding<Bool> {
        Binding(
            get: { actionError != nil },
            set: { isPresented in
                if !isPresented {
                    actionError = nil
                }
            }
        )
    }

    private var isRecording: Bool {
        recordingStartedAt != nil
    }

    private var trackStatusText: String {
        guard let recordingStartedAt else {
            return "Recording is off."
        }

        if recordingPaused {
            return recordingPauseReason ?? "Paused since \(recordingStartedAt.formatted(date: .omitted, time: .shortened))."
        }

        return "Recording since \(recordingStartedAt.formatted(date: .omitted, time: .shortened))."
    }

    private func coordinateLine(
        label: String,
        coordinate: CLLocationCoordinate2D?,
        fallbackText: String
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button("Copy Decimal") {
                    guard let coordinate else { return }
                    UIPasteboard.general.string = RescueCoordinateFormatter.decimalDegreesString(from: coordinate)
                    hapticFeedbackService?.play(.success)
                }
                .font(.caption.weight(.medium))
                .disabled(coordinate == nil)
            }

            if let coordinate {
                Text(RescueCoordinateFormatter.string(from: coordinate, format: coordinateFormat))
                    .font(.body.monospaced())
                Text(RescueCoordinateFormatter.decimalDegreesString(from: coordinate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(fallbackText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func waypointRow(_ waypoint: UserWaypoint) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Label(waypoint.title, systemImage: waypoint.symbolName ?? waypoint.category.symbolName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(waypoint.category.pinColor)
                Spacer()
                Menu {
                    Button("Edit") {
                        editingWaypoint = waypoint
                        waypointDraftCoordinate = waypoint.coordinate
                        showingWaypointEditor = true
                    }

                    Button("Copy Decimal Coordinates") {
                        UIPasteboard.general.string = RescueCoordinateFormatter.decimalDegreesString(from: waypoint.coordinate)
                    }

                    Button("Delete", role: .destructive) {
                        deleteWaypoint(waypoint)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }

            Text(RescueCoordinateFormatter.string(from: waypoint.coordinate, format: coordinateFormat))
                .font(.body.monospaced())

            if let note = waypoint.note, !note.isEmpty {
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(.osaBackground, in: RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    @ViewBuilder
    private func trackRow(_ track: RecordedTrack) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(track.title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Menu {
                    Button("Export GPX") {
                        exportTrack(track)
                    }

                    Button("Delete", role: .destructive) {
                        deleteTrack(track)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }

            Text("\(track.points.count) points • \(NavigationDistanceCalculator.formattedDistance(track.totalDistanceMeters))")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Duration: \(NavigationDistanceCalculator.formattedDuration(track.duration))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(.osaBackground, in: RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    @ViewBuilder
    private func cachedRegionRow(_ region: CachedTileRegion) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(region.name)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button(role: .destructive) {
                    deleteCachedRegion(region)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
            }

            Text(RescueCoordinateFormatter.degreesDecimalMinutesString(from: region.centerCoordinate))
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)

            Text("\(region.tileCount) tiles • z\(region.zoomRange.lowerBound)-\(region.zoomRange.upperBound) • \(ByteCountFormatter.string(fromByteCount: region.sizeBytes, countStyle: .file))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(.osaBackground, in: RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    private func loadData() {
        annotations = annotationProvider?.allAnnotations() ?? []
        loadWaypoints()
        loadTracks()
        loadCachedRegions()
        updateDisplayMode()
    }

    private func loadWaypoints() {
        do {
            waypoints = try waypointRepository?.listWaypoints() ?? []
        } catch {
            actionError = "Waypoints could not be loaded."
        }
    }

    private func loadTracks() {
        do {
            tracks = try recordedTrackRepository?.listTracks() ?? []
        } catch {
            actionError = "Recorded tracks could not be loaded."
        }
    }

    private func loadCachedRegions() {
        cachedRegions = tileCacheService?.cachedRegions() ?? []
        updateDisplayMode()
    }

    private func observeConnectivity() async {
        guard let service = connectivityService else { return }
        connectivity = service.currentState
        updateDisplayMode()

        for await state in service.stateStream() {
            connectivity = state
            updateDisplayMode()
        }
    }

    private func observeLocationSamples() async {
        guard let service = locationService else { return }
        // Authorization is requested only when the user explicitly triggers a
        // location-requiring action (e.g. Start Track Recording). Eagerly prompting
        // here violates iOS best practices and breaks UI tests that run before
        // the Maps tab is selected.
        for await location in service.locationUpdateStream() {
            userLocation = location.coordinate
            if isRecording, !recordingPaused {
                appendTrackSample(location)
            }
        }
    }

    private func observeAuthorization() async {
        guard let service = locationService else { return }

        for await status in service.authorizationStatusStream() {
            locationAuthStatus = status
            if status != .authorizedWhenInUse && status != .authorizedAlways, isRecording {
                pauseRecording(reason: "Paused because location access is no longer available.")
            }
        }
    }

    private func observeHeading() async {
        guard let service = locationService, service.isHeadingAvailable else { return }

        for await heading in service.headingStream() {
            currentHeading = heading
        }
    }

    private func beginWaypointCreation(at coordinate: CLLocationCoordinate2D) {
        editingWaypoint = nil
        waypointDraftCoordinate = coordinate
        showingWaypointEditor = true
    }

    private func saveWaypoint(_ waypoint: UserWaypoint) {
        do {
            if editingWaypoint == nil {
                try waypointRepository?.createWaypoint(waypoint)
            } else {
                try waypointRepository?.updateWaypoint(waypoint)
            }
            editingWaypoint = nil
            loadWaypoints()
            hapticFeedbackService?.play(.success)
        } catch {
            actionError = "That waypoint could not be saved."
            hapticFeedbackService?.play(.error)
        }
    }

    private func deleteWaypoint(_ waypoint: UserWaypoint) {
        do {
            try waypointRepository?.deleteWaypoint(id: waypoint.id)
            loadWaypoints()
            hapticFeedbackService?.play(.warning)
        } catch {
            actionError = "That waypoint could not be deleted."
            hapticFeedbackService?.play(.error)
        }
    }

    private func startRecording() {
        guard let locationService else {
            actionError = "Location services are unavailable."
            return
        }

        let status = locationService.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            locationService.requestWhenInUseAuthorization()
            actionError = "Allow when-in-use location access to record a track."
            return
        }

        recordingStartedAt = Date()
        recordingPaused = false
        recordingPauseReason = nil
        recordingSamples.removeAll()

        if let userLocation {
            recordingSamples.append(
                RecordedTrackPoint(
                    id: UUID(),
                    latitude: userLocation.latitude,
                    longitude: userLocation.longitude,
                    timestamp: Date(),
                    horizontalAccuracy: 0
                )
            )
        }

        hapticFeedbackService?.play(.success)
    }

    private func pauseRecording(reason: String) {
        guard isRecording else { return }
        recordingPaused = true
        recordingPauseReason = reason
        hapticFeedbackService?.play(.warning)
    }

    private func resumeRecording() {
        guard isRecording else { return }

        let status = locationService?.authorizationStatus ?? .denied
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            actionError = "Location access is still unavailable, so recording cannot resume."
            return
        }

        recordingPaused = false
        recordingPauseReason = nil
        hapticFeedbackService?.play(.success)
    }

    private func stopRecording() {
        guard let startedAt = recordingStartedAt else { return }

        let now = Date()
        let track = RecordedTrack(
            id: UUID(),
            title: "Track \(startedAt.formatted(date: .abbreviated, time: .shortened))",
            startedAt: startedAt,
            endedAt: now,
            totalDistanceMeters: NavigationDistanceCalculator.cumulativeDistance(for: recordingSamples),
            points: recordingSamples
        )

        do {
            try recordedTrackRepository?.createTrack(track)
            recordingStartedAt = nil
            recordingPaused = false
            recordingPauseReason = nil
            recordingSamples.removeAll()
            loadTracks()
            hapticFeedbackService?.play(.success)
        } catch {
            actionError = "The recorded track could not be saved."
            hapticFeedbackService?.play(.error)
        }
    }

    private func appendTrackSample(_ location: CLLocation) {
        guard location.horizontalAccuracy >= 0, location.horizontalAccuracy <= 100 else {
            return
        }

        let newPoint = RecordedTrackPoint(
            id: UUID(),
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            timestamp: location.timestamp,
            horizontalAccuracy: location.horizontalAccuracy
        )

        guard let lastPoint = recordingSamples.last else {
            recordingSamples.append(newPoint)
            return
        }

        let lastLocation = CLLocation(latitude: lastPoint.latitude, longitude: lastPoint.longitude)
        let distance = lastLocation.distance(from: location)
        let timeDelta = location.timestamp.timeIntervalSince(lastPoint.timestamp)

        guard distance >= 5 || timeDelta >= 15 else {
            return
        }

        recordingSamples.append(newPoint)
    }

    private func exportTrack(_ track: RecordedTrack) {
        do {
            let fileURL = try GPXExporter.exportFile(for: track)
            sharePayload = ActivitySharePayload(items: [fileURL], subject: track.title)
        } catch {
            actionError = "That GPX export could not be generated."
            hapticFeedbackService?.play(.error)
        }
    }

    private func deleteTrack(_ track: RecordedTrack) {
        do {
            try recordedTrackRepository?.deleteTrack(id: track.id)
            loadTracks()
            hapticFeedbackService?.play(.warning)
        } catch {
            actionError = "That track could not be deleted."
            hapticFeedbackService?.play(.error)
        }
    }

    private func deleteCachedRegion(_ region: CachedTileRegion) {
        do {
            try tileCacheService?.deleteCachedRegion(id: region.id)
            loadCachedRegions()
            hapticFeedbackService?.play(.warning)
        } catch {
            actionError = "That offline region could not be deleted."
            hapticFeedbackService?.play(.error)
        }
    }

    private func updateDisplayMode() {
        if connectivity == .onlineUsable {
            displayMode = .online
        } else if !cachedRegions.isEmpty {
            displayMode = .offlineCachedTiles
        } else {
            displayMode = .offlineNoTiles
        }
    }

    private func openInAppleMaps() {
        let coordinate = userLocation ?? visibleRegion.centerCoordinate
        guard let url = URL(string: "maps://?q=emergency+shelter&near=\(coordinate.latitude),\(coordinate.longitude)") else {
            return
        }
        UIApplication.shared.open(url)
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var icon: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xxs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption2)
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(
                isSelected ? Color.osaPrimary.opacity(0.15) : Color.osaElevatedSurface,
                in: Capsule()
            )
            .foregroundStyle(isSelected ? Color.osaPrimary : .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint(title == "All" ? "Shows all map locations." : "Filters the map to \(title.lowercased()) locations.")
    }
}
