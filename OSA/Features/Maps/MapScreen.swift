import SwiftUI
import MapKit
import CoreLocation

struct MapScreen: View {
    @Environment(\.connectivityService) private var connectivityService
    @Environment(\.locationService) private var locationService
    @Environment(\.mapAnnotationProvider) private var annotationProvider
    @Environment(\.tileCacheService) private var tileCacheService

    @State private var connectivity: ConnectivityState = .offline
    @State private var displayMode: MapDisplayMode = .online
    @State private var annotations: [MapAnnotationItem] = []
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var selectedCategory: MapAnnotationCategory?

    private let defaultCenter = CLLocationCoordinate2D(latitude: 45.5152, longitude: -122.6784)
    private let initialCategory: MapAnnotationCategory?

    init(initialCategory: MapAnnotationCategory? = nil) {
        self.initialCategory = initialCategory
        _selectedCategory = State(initialValue: initialCategory)
    }

    var body: some View {
        VStack(spacing: 0) {
            categoryFilterBar
            mapContent
            if displayMode != .online {
                offlineBanner
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
                    Button("Open in Apple Maps", systemImage: "apple.logo") {
                        openInAppleMaps()
                    }
                    if tileCacheService?.cachedRegions().isEmpty == false {
                        Button("Offline Tiles", systemImage: "map.fill") {
                            displayMode = .offlineCachedTiles
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task { loadAnnotations() }
        .task { await observeConnectivity() }
        .task { await observeLocation() }
    }

    // MARK: - Category Filter

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

    // MARK: - Map Content

    @ViewBuilder
    private var mapContent: some View {
        switch displayMode {
        case .online:
            OnlineMapView(annotations: filteredAnnotations, userLocation: userLocation)
        case .offlineCachedTiles:
            if let service = tileCacheService {
                OfflineTileMapView(
                    annotations: filteredAnnotations,
                    tileCacheService: service,
                    userLocation: userLocation
                )
            }
        case .offlineAppleMaps:
            offlineAppleMapsPrompt
        case .offlineNoTiles:
            offlineStaticContent
        }
    }

    private var filteredAnnotations: [MapAnnotationItem] {
        guard let category = selectedCategory else { return annotations }
        return annotations.filter { $0.category == category }
    }

    // MARK: - Offline States

    private var offlineBanner: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "wifi.slash")
                .font(.caption)
            Text("Offline mode")
                .font(.caption)
                .fontWeight(.medium)
            Spacer()
            Button("Open Apple Maps") {
                openInAppleMaps()
            }
            .font(.caption)
            .fontWeight(.medium)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(Color.osaWarning.opacity(0.12))
        .foregroundStyle(Color.osaWarning)
    }

    private var offlineAppleMapsPrompt: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "map.fill")
                .font(.largeTitle)
                .foregroundStyle(.osaCalm)
            Text("Map Unavailable Offline")
                .font(.headline)
            Text("Open Apple Maps to use downloaded offline maps, or connect to the internet for live maps.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open Apple Maps") {
                openInAppleMaps()
            }
            .buttonStyle(.borderedProminent)
            .tint(.osaPrimary)
        }
        .padding(Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var offlineStaticContent: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "map.fill")
                .font(.largeTitle)
                .foregroundStyle(.osaCalm)
            Text("No Cached Map Tiles")
                .font(.headline)
            Text("Connect to the internet to browse maps and build a local cache for offline use.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func loadAnnotations() {
        annotations = annotationProvider?.allAnnotations() ?? []
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

    private func observeLocation() async {
        guard let service = locationService else { return }
        service.requestWhenInUseAuthorization()
        for await coordinate in service.locationStream() {
            userLocation = coordinate
        }
    }

    private func updateDisplayMode() {
        if connectivity == .onlineUsable {
            displayMode = .online
        } else if let cache = tileCacheService, !cache.cachedRegions().isEmpty {
            displayMode = .offlineCachedTiles
        } else {
            displayMode = .offlineAppleMaps
        }
    }

    private func openInAppleMaps() {
        let coordinate = userLocation ?? defaultCenter
        if let url = URL(string: "maps://?q=emergency+shelter&near=\(coordinate.latitude),\(coordinate.longitude)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Filter Chip

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
    }
}
