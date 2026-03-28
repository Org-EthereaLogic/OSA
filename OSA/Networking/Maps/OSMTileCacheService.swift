import Foundation

/// Manages cached OpenStreetMap tiles on disk for offline map access.
final class OSMTileCacheService: TileCacheService, @unchecked Sendable {
    private let cacheDirectory: URL
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("OSMTiles", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func hasCachedTiles(for region: CachedTileRegion) -> Bool {
        let regionDir = cacheDirectory.appendingPathComponent(region.id.uuidString)
        return fileManager.fileExists(atPath: regionDir.path)
    }

    func cachedRegions() -> [CachedTileRegion] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ) else { return [] }

        return contents.compactMap { url in
            guard let id = UUID(uuidString: url.lastPathComponent) else { return nil }
            let created = (try? url.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date()
            return CachedTileRegion(
                id: id,
                name: url.lastPathComponent,
                centerLatitude: 0,
                centerLongitude: 0,
                zoomRange: 1...15,
                tileCount: 0,
                downloadedAt: created,
                sizeBytes: 0
            )
        }
    }

    func tileData(x: Int, y: Int, z: Int) -> Data? {
        let tilePath = cacheDirectory
            .appendingPathComponent("\(z)")
            .appendingPathComponent("\(x)")
            .appendingPathComponent("\(y).png")
        return fileManager.contents(atPath: tilePath.path)
    }

    /// Caches a tile fetched from OSM.
    func storeTile(data: Data, x: Int, y: Int, z: Int) {
        let dir = cacheDirectory
            .appendingPathComponent("\(z)")
            .appendingPathComponent("\(x)")
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        let tilePath = dir.appendingPathComponent("\(y).png")
        fileManager.createFile(atPath: tilePath.path, contents: data)
    }
}
