import SwiftUI
import CoreLocation
import WeatherKit

struct WeatherScreen: View {
    @Environment(\.weatherForecastRepository) private var forecastRepository
    @Environment(\.weatherForecastService) private var forecastService
    @Environment(\.weatherAlertService) private var alertService
    @Environment(\.connectivityService) private var connectivityService

    @State private var forecastState: HomeSectionState<[DailyForecast]> = .loading
    @State private var alertsState: HomeSectionState<[WeatherAlert]> = .loading
    @State private var cacheInfo: ForecastCacheInfo?
    @State private var connectivity: ConnectivityState = .offline
    @State private var attributionMarkURL: URL?
    @State private var attributionLegalURL: URL?

    private let defaultLocation = CLLocationCoordinate2D(latitude: 45.5152, longitude: -122.6784)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                weatherHeader
                alertsSection
                forecastSection
                attributionSection
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.lg)
        }
        .background(.osaBackground)
        .navigationTitle("Weather")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadWeather() }
        .task { await observeConnectivity() }
        .refreshable { await refreshWeather() }
    }

    // MARK: - Header

    private var weatherHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "cloud.sun.fill")
                    .font(.title)
                    .foregroundStyle(Color.osaPrimary)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("WEATHER & ALERTS")
                        .font(.brandEyebrow)
                        .foregroundStyle(Color.white.opacity(0.72))
                        .tracking(1.1)
                    Text("Pacific Northwest forecasts and emergency alerts.")
                        .font(.brandSubheadline)
                        .foregroundStyle(Color.white.opacity(0.84))
                }
            }
            if let info = cacheInfo {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: info.isStale ? "exclamationmark.circle" : "checkmark.circle")
                        .font(.caption)
                    Text(info.stalenessDescription)
                        .font(.metadataCaption)
                }
                .foregroundStyle(info.isStale ? Color.osaWarning : .secondary)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.osaCanopy, Color.osaPine, Color.osaNight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: CornerRadius.xl)
        )
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(Color.osaPrimary.opacity(0.24), lineWidth: 1)
        }
    }

    // MARK: - Alerts Section

    private var alertsSection: some View {
        Group {
            switch alertsState {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 60)
            case .empty:
                Label("No active weather alerts", systemImage: "checkmark.shield")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, Spacing.md)
            case .failed(let message):
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.subheadline)
                    .foregroundStyle(.osaWarning)
            case .loaded(let alerts):
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Active Alerts")
                        .font(.sectionHeader)
                        .foregroundStyle(.primary)
                    ForEach(alerts) { alert in
                        WeatherAlertRow(alert: alert)
                    }
                }
            }
        }
    }

    // MARK: - Forecast Section

    private var forecastSection: some View {
        Group {
            switch forecastState {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            case .empty:
                Label("No forecast data available", systemImage: "cloud.slash")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, Spacing.md)
            case .failed(let message):
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.subheadline)
                    .foregroundStyle(.osaWarning)
            case .loaded(let forecasts):
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("10-Day Forecast")
                        .font(.sectionHeader)
                        .foregroundStyle(.primary)
                    ForEach(forecasts) { forecast in
                        WeatherForecastRow(forecast: forecast)
                    }
                }
                .padding(Spacing.lg)
                .background(Color.osaSurface, in: RoundedRectangle(cornerRadius: CornerRadius.lg))
            }
        }
    }

    // MARK: - Attribution

    private var attributionSection: some View {
        Group {
            if attributionMarkURL != nil || attributionLegalURL != nil {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    if let markURL = attributionMarkURL {
                        AsyncImage(url: markURL) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            EmptyView()
                        }
                        .frame(height: 14)
                    }
                    if let legalURL = attributionLegalURL {
                        Link("Weather data attribution", destination: legalURL)
                            .font(.metadataCaption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.top, Spacing.md)
            }
        }
    }

    // MARK: - Loading

    private func loadWeather() async {
        // Offline-first: show cached data immediately
        if let repo = forecastRepository {
            if let forecasts = try? repo.cachedForecasts(), !forecasts.isEmpty {
                forecastState = .loaded(forecasts)
            }
            if let alerts = try? repo.activeAlerts(), !alerts.isEmpty {
                alertsState = .loaded(alerts)
            }
            cacheInfo = try? repo.cacheInfo()
        }

        // Fetch fresh data if online
        await refreshWeather()

        // Load attribution
        if let service = forecastService {
            if let attr = await service.attribution() {
                attributionMarkURL = attr.markURL
                attributionLegalURL = attr.legalURL
            }
        }
    }

    private func refreshWeather() async {
        guard connectivity == .onlineUsable else { return }

        // Fetch forecasts
        if let service = forecastService {
            do {
                let forecasts = try await service.fetchTenDayForecast(for: defaultLocation)
                try? forecastRepository?.replaceForecasts(forecasts)
                forecastState = forecasts.isEmpty ? .empty : .loaded(forecasts)
                cacheInfo = try? forecastRepository?.cacheInfo()
            } catch {
                if case .loading = forecastState {
                    forecastState = .failed("Unable to load forecast")
                }
            }
        }

        // Fetch alerts
        if let service = alertService {
            let alerts = await service.fetchAlerts()
            try? forecastRepository?.replaceAlerts(alerts)
            let active = alerts.filter { alert in
                guard let expires = alert.expiresDate else { return true }
                return expires > Date()
            }
            alertsState = active.isEmpty ? .empty : .loaded(active)
        }
    }

    private func observeConnectivity() async {
        guard let service = connectivityService else { return }
        connectivity = service.currentState
        for await state in service.stateStream() {
            connectivity = state
        }
    }
}
