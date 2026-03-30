import Foundation

protocol OSMTileDownloading: Sendable {
    func data(for url: URL) async throws -> Data
}

struct URLSessionTileDownloader: OSMTileDownloading {
    func data(for url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}

/// Manages cached OpenStreetMap tiles on disk for offline map access.
final class OSMTileCacheService: TileCacheService, @unchecked Sendable {
    private struct RegionManifest: Codable {
        let id: UUID
        let name: String
        let centerLatitude: Double
        let centerLongitude: Double
        let zoomLowerBound: Int
        let zoomUpperBound: Int
        let tileCount: Int
        let downloadedAt: Date
        let sizeBytes: Int64
        let tileCoordinates: [MapTileCoordinate]

        var cachedRegion: CachedTileRegion {
            CachedTileRegion(
                id: id,
                name: name,
                centerLatitude: centerLatitude,
                centerLongitude: centerLongitude,
                zoomRange: zoomLowerBound...zoomUpperBound,
                tileCount: tileCount,
                downloadedAt: downloadedAt,
                sizeBytes: sizeBytes
            )
        }
    }

    let regionBudget: TileRegionBudget

    private let cacheDirectory: URL
    private let tilesDirectory: URL
    private let metadataURL: URL
    private let fileManager: FileManager
    private let downloader: any OSMTileDownloading
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    init(
        fileManager: FileManager = .default,
        cacheDirectory: URL? = nil,
        downloader: any OSMTileDownloading = URLSessionTileDownloader(),
        regionBudget: TileRegionBudget = .standard
    ) {
        self.fileManager = fileManager
        self.downloader = downloader
        self.regionBudget = regionBudget

        let baseDirectory = cacheDirectory ?? fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("OSMTiles", isDirectory: true)
        self.cacheDirectory = baseDirectory
        self.tilesDirectory = baseDirectory.appendingPathComponent("tiles", isDirectory: true)
        self.metadataURL = baseDirectory.appendingPathComponent("regions.json")

        try? fileManager.createDirectory(at: tilesDirectory, withIntermediateDirectories: true)
    }

    func hasCachedTiles(for region: CachedTileRegion) -> Bool {
        cachedRegions().contains { $0.id == region.id }
    }

    func cachedRegions() -> [CachedTileRegion] {
        loadManifests()
            .map(\.cachedRegion)
            .sorted { $0.downloadedAt > $1.downloadedAt }
    }

    func totalCacheSizeBytes() -> Int64 {
        uniqueTileCoordinates(from: loadManifests()).reduce(0) { partial, tile in
            partial + fileSize(at: tileFileURL(for: tile))
        }
    }

    func planRegionSave(
        name: String,
        region: MapRegion,
        zoomRange: ClosedRange<Int>
    ) throws -> TileRegionSavePlan {
        guard zoomRange.lowerBound <= zoomRange.upperBound else {
            throw TileRegionPlanningError.invalidZoomRange
        }

        let tileCoordinates = tileCoordinates(for: region, zoomRange: zoomRange)
        guard tileCoordinates.count <= regionBudget.maxTilesPerRegion else {
            throw TileRegionPlanningError.tileCountExceedsLimit(
                requested: tileCoordinates.count,
                limit: regionBudget.maxTilesPerRegion
            )
        }

        let manifests = loadManifests()
        let existingTiles = uniqueTileCoordinates(from: manifests)
        let newTileCoordinates = tileCoordinates.filter { !existingTiles.contains($0) }
        let projectedCacheSizeBytes = totalCacheSizeBytes()
            + (Int64(newTileCoordinates.count) * regionBudget.estimatedBytesPerTile)

        guard projectedCacheSizeBytes <= regionBudget.maxCacheSizeBytes else {
            throw TileRegionPlanningError.cacheBudgetExceeded(
                projectedBytes: projectedCacheSizeBytes,
                limitBytes: regionBudget.maxCacheSizeBytes
            )
        }

        return TileRegionSavePlan(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Offline Region" : name,
            region: region,
            zoomRange: zoomRange,
            tileCount: tileCoordinates.count,
            newTileCount: newTileCoordinates.count,
            estimatedSizeBytes: Int64(tileCoordinates.count) * regionBudget.estimatedBytesPerTile,
            projectedCacheSizeBytes: projectedCacheSizeBytes,
            tileCoordinates: tileCoordinates
        )
    }

    func saveRegion(using plan: TileRegionSavePlan) async throws -> CachedTileRegion {
        var regionSizeBytes: Int64 = 0

        for tile in plan.tileCoordinates {
            let fileURL = tileFileURL(for: tile)
            if fileManager.fileExists(atPath: fileURL.path) {
                regionSizeBytes += fileSize(at: fileURL)
                continue
            }

            let tileData = try await downloader.data(for: tileURL(for: tile))
            let parentDirectory = fileURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
            try tileData.write(to: fileURL, options: .atomic)
            regionSizeBytes += Int64(tileData.count)
        }

        var manifests = loadManifests()
        let manifest = RegionManifest(
            id: plan.id,
            name: plan.name,
            centerLatitude: plan.region.centerLatitude,
            centerLongitude: plan.region.centerLongitude,
            zoomLowerBound: plan.zoomRange.lowerBound,
            zoomUpperBound: plan.zoomRange.upperBound,
            tileCount: plan.tileCount,
            downloadedAt: Date(),
            sizeBytes: regionSizeBytes,
            tileCoordinates: plan.tileCoordinates
        )
        manifests.removeAll { $0.id == plan.id }
        manifests.append(manifest)
        try saveManifests(manifests)

        return manifest.cachedRegion
    }

    func deleteCachedRegion(id: UUID) throws {
        var manifests = loadManifests()
        guard let index = manifests.firstIndex(where: { $0.id == id }) else {
            return
        }

        let removed = manifests.remove(at: index)
        let retainedTiles = uniqueTileCoordinates(from: manifests)

        for tile in removed.tileCoordinates where !retainedTiles.contains(tile) {
            let tileFileURL = tileFileURL(for: tile)
            if fileManager.fileExists(atPath: tileFileURL.path) {
                try? fileManager.removeItem(at: tileFileURL)
                pruneIfEmpty(directory: tileFileURL.deletingLastPathComponent())
            }
        }

        try saveManifests(manifests)
    }

    func tileData(x: Int, y: Int, z: Int) -> Data? {
        fileManager.contents(atPath: tileFileURL(for: MapTileCoordinate(x: x, y: y, z: z)).path)
    }

    private func loadManifests() -> [RegionManifest] {
        guard fileManager.fileExists(atPath: metadataURL.path),
              let data = try? Data(contentsOf: metadataURL),
              let manifests = try? jsonDecoder.decode([RegionManifest].self, from: data) else {
            return []
        }

        return manifests
    }

    private func saveManifests(_ manifests: [RegionManifest]) throws {
        let data = try jsonEncoder.encode(manifests)
        try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        try data.write(to: metadataURL, options: .atomic)
    }

    private func uniqueTileCoordinates(from manifests: [RegionManifest]) -> Set<MapTileCoordinate> {
        Set(manifests.flatMap(\.tileCoordinates))
    }

    private func tileCoordinates(
        for region: MapRegion,
        zoomRange: ClosedRange<Int>
    ) -> [MapTileCoordinate] {
        let northLatitude = min(85.051_128_78, region.latitudeRange.upperBound)
        let southLatitude = max(-85.051_128_78, region.latitudeRange.lowerBound)
        let westLongitude = max(-180, region.longitudeRange.lowerBound)
        let eastLongitude = min(180, region.longitudeRange.upperBound)

        var coordinates: [MapTileCoordinate] = []

        for zoom in zoomRange {
            let maxIndex = (1 << zoom) - 1
            let minX = clampedTileIndex(longitudeToTileX(westLongitude, zoom: zoom), maxIndex: maxIndex)
            let maxX = clampedTileIndex(longitudeToTileX(eastLongitude, zoom: zoom), maxIndex: maxIndex)
            let minY = clampedTileIndex(latitudeToTileY(northLatitude, zoom: zoom), maxIndex: maxIndex)
            let maxY = clampedTileIndex(latitudeToTileY(southLatitude, zoom: zoom), maxIndex: maxIndex)

            for x in minX...maxX {
                for y in minY...maxY {
                    coordinates.append(MapTileCoordinate(x: x, y: y, z: zoom))
                }
            }
        }

        return coordinates
    }

    private func longitudeToTileX(_ longitude: Double, zoom: Int) -> Int {
        let scale = Double(1 << zoom)
        return Int(floor((longitude + 180) / 360 * scale))
    }

    private func latitudeToTileY(_ latitude: Double, zoom: Int) -> Int {
        let scale = Double(1 << zoom)
        let latitudeRadians = latitude * .pi / 180
        let mercator = log(tan(.pi / 4 + latitudeRadians / 2))
        return Int(floor((1 - mercator / .pi) / 2 * scale))
    }

    private func clampedTileIndex(_ index: Int, maxIndex: Int) -> Int {
        min(max(index, 0), maxIndex)
    }

    private func tileURL(for tile: MapTileCoordinate) -> URL {
        URL(string: "https://tile.openstreetmap.org/\(tile.z)/\(tile.x)/\(tile.y).png")!
    }

    private func tileFileURL(for tile: MapTileCoordinate) -> URL {
        tilesDirectory
            .appendingPathComponent("\(tile.z)", isDirectory: true)
            .appendingPathComponent("\(tile.x)", isDirectory: true)
            .appendingPathComponent("\(tile.y).png", isDirectory: false)
    }

    private func fileSize(at url: URL) -> Int64 {
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? NSNumber else {
            return 0
        }

        return fileSize.int64Value
    }

    private func pruneIfEmpty(directory: URL) {
        guard directory.path.hasPrefix(tilesDirectory.path) else { return }
        guard let contents = try? fileManager.contentsOfDirectory(atPath: directory.path),
              contents.isEmpty else {
            return
        }

        try? fileManager.removeItem(at: directory)
        pruneIfEmpty(directory: directory.deletingLastPathComponent())
    }
}
