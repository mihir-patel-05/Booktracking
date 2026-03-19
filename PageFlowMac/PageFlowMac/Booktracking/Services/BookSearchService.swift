import Foundation

struct OpenLibrarySearchResult: Decodable {
    let docs: [OpenLibraryDoc]
}

struct OpenLibraryDoc: Decodable, Identifiable {
    let key: String
    let title: String
    let author_name: [String]?
    let cover_i: Int?
    let number_of_pages_median: Int?

    var id: String { key }

    var authorDisplay: String {
        author_name?.first ?? "Unknown Author"
    }

    var coverURL: String? {
        guard let coverId = cover_i else { return nil }
        return "https://covers.openlibrary.org/b/id/\(coverId)-M.jpg"
    }

    var pageCount: Int {
        number_of_pages_median ?? 0
    }
}

actor BookSearchService {
    private let session = URLSession.shared
    private let baseURL = "https://openlibrary.org/search.json"

    func search(query: String, limit: Int = 20) async throws -> [OpenLibraryDoc] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }

        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "q", value: trimmed),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "fields", value: "key,title,author_name,cover_i,number_of_pages_median")
        ]

        guard let url = components.url else { return [] }

        let (data, _) = try await session.data(from: url)
        let result = try JSONDecoder().decode(OpenLibrarySearchResult.self, from: data)
        return result.docs
    }
}
