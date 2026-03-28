import Foundation
import SQLite3

final class SearchIndexStore {
    private var db: OpaquePointer?

    init(path: String) throws {
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK else {
            let message = db.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "Unknown error"
            throw SearchIndexError.openFailed(message)
        }

        try execute("""
            CREATE VIRTUAL TABLE IF NOT EXISTS search_index USING fts5(
                entry_id UNINDEXED,
                kind UNINDEXED,
                title,
                body,
                tags,
                tokenize='porter unicode61'
            )
        """)
    }

    /// In-memory initializer for tests
    convenience init() throws {
        try self.init(path: ":memory:")
    }

    deinit {
        sqlite3_close(db)
    }

    func upsert(id: UUID, kind: SearchResultKind, title: String, body: String, tags: String) throws {
        try removeEntry(id: id)
        try execute(
            "INSERT INTO search_index (entry_id, kind, title, body, tags) VALUES (?, ?, ?, ?, ?)",
            bindings: [id.uuidString, kind.rawValue, title, body, tags]
        )
    }

    func removeEntry(id: UUID) throws {
        try execute(
            "DELETE FROM search_index WHERE entry_id = ?",
            bindings: [id.uuidString]
        )
    }

    func removeAll() throws {
        try execute("DELETE FROM search_index")
    }

    func query(text: String, kindFilter: Set<SearchResultKind>?, limit: Int) throws -> [SearchIndexEntry] {
        let normalized = normalizeQuery(text)
        guard !normalized.isEmpty else { return [] }

        var sql = """
            SELECT entry_id, kind, highlight(search_index, 2, '<b>', '</b>') AS title_hl,
                   snippet(search_index, 3, '<b>', '</b>', '...', 32) AS body_snip,
                   tags,
                   bm25(search_index) AS rank
            FROM search_index
            WHERE search_index MATCH ?
        """

        var bindings: [String] = [normalized]

        if let kindFilter, !kindFilter.isEmpty {
            let placeholders = kindFilter.map { _ in "?" }.joined(separator: ", ")
            sql += " AND kind IN (\(placeholders))"
            bindings.append(contentsOf: kindFilter.map(\.rawValue))
        }

        sql += " ORDER BY rank LIMIT ?"
        bindings.append(String(limit))

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            let message = db.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "Unknown error"
            throw SearchIndexError.queryFailed(message)
        }
        defer { sqlite3_finalize(stmt) }

        for (index, value) in bindings.enumerated() {
            sqlite3_bind_text(stmt, Int32(index + 1), (value as NSString).utf8String, -1, nil)
        }

        var results: [SearchIndexEntry] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let entryID = String(cString: sqlite3_column_text(stmt, 0))
            let kind = String(cString: sqlite3_column_text(stmt, 1))
            let titleHL = String(cString: sqlite3_column_text(stmt, 2))
            let bodySnippet = String(cString: sqlite3_column_text(stmt, 3))
            let rawTags = String(cString: sqlite3_column_text(stmt, 4))
            let rank = sqlite3_column_double(stmt, 5)

            if let uuid = UUID(uuidString: entryID),
               let resultKind = SearchResultKind(rawValue: kind) {
                results.append(SearchIndexEntry(
                    id: uuid,
                    kind: resultKind,
                    title: titleHL.replacingOccurrences(of: "<b>", with: "").replacingOccurrences(of: "</b>", with: ""),
                    snippet: bodySnippet.replacingOccurrences(of: "<b>", with: "").replacingOccurrences(of: "</b>", with: ""),
                    score: -rank,
                    tags: rawTags
                        .split(separator: " ")
                        .map(String.init)
                ))
            }
        }

        return results
    }

    func suggestions(prefix: String, limit: Int) throws -> [SearchSuggestion] {
        let trimmed = prefix.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }

        var suggestions: [SearchSuggestion] = []
        suggestions.append(contentsOf: try titleSuggestions(prefix: trimmed, limit: limit))
        suggestions.append(contentsOf: try tagSuggestions(prefix: trimmed, limit: limit))

        var seen = Set<String>()
        return suggestions.filter { suggestion in
            let key = suggestion.text.lowercased()
            if seen.contains(key) {
                return false
            }
            seen.insert(key)
            return true
        }
        .prefix(limit)
        .map { $0 }
    }

    private func normalizeQuery(_ text: String) -> String {
        let stripped = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .alphanumerics.inverted)
            .filter { !$0.isEmpty }

        guard !stripped.isEmpty else { return "" }

        if stripped.count == 1 {
            return stripped[0] + "*"
        }

        return stripped.map { $0 + "*" }.joined(separator: " ")
    }

    private func execute(_ sql: String, bindings: [String] = []) throws {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            let message = db.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "Unknown error"
            throw SearchIndexError.executeFailed(message)
        }
        defer { sqlite3_finalize(stmt) }

        for (index, value) in bindings.enumerated() {
            sqlite3_bind_text(stmt, Int32(index + 1), (value as NSString).utf8String, -1, nil)
        }

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            let message = db.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "Unknown error"
            throw SearchIndexError.executeFailed(message)
        }
    }

    private func titleSuggestions(prefix: String, limit: Int) throws -> [SearchSuggestion] {
        try simpleTextQuery(
            sql: """
                SELECT DISTINCT title
                FROM search_index
                WHERE lower(title) LIKE ?
                ORDER BY title
                LIMIT ?
            """,
            bindings: ["\(prefix)%", String(limit)]
        )
        .map { SearchSuggestion(text: $0, source: .title) }
    }

    private func tagSuggestions(prefix: String, limit: Int) throws -> [SearchSuggestion] {
        let raws = try simpleTextQuery(
            sql: """
                SELECT tags
                FROM search_index
                WHERE lower(tags) LIKE ?
                   OR lower(tags) LIKE ?
                   OR lower(tags) LIKE ?
                LIMIT ?
            """,
            bindings: ["\(prefix)%", "% \(prefix)%", "%:\(prefix)%", String(limit * 4)]
        )

        let tags = raws
            .flatMap { $0.split(separator: " ").map(String.init) }
            .filter { $0.lowercased().contains(prefix) || $0.lowercased().hasPrefix(prefix) }
            .sorted()

        var seen = Set<String>()
        return tags.filter { tag in
            let key = tag.lowercased()
            if seen.contains(key) {
                return false
            }
            seen.insert(key)
            return true
        }
        .prefix(limit)
        .map { SearchSuggestion(text: $0, source: .tag) }
    }

    private func simpleTextQuery(sql: String, bindings: [String]) throws -> [String] {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            let message = db.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "Unknown error"
            throw SearchIndexError.queryFailed(message)
        }
        defer { sqlite3_finalize(stmt) }

        for (index, value) in bindings.enumerated() {
            sqlite3_bind_text(stmt, Int32(index + 1), (value as NSString).utf8String, -1, nil)
        }

        var results: [String] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let text = sqlite3_column_text(stmt, 0) else { continue }
            results.append(String(cString: text))
        }

        return results
    }
}

struct SearchIndexEntry {
    let id: UUID
    let kind: SearchResultKind
    let title: String
    let snippet: String
    let score: Double
    let tags: [String]
}

enum SearchIndexError: Error {
    case openFailed(String)
    case executeFailed(String)
    case queryFailed(String)
}
