import Foundation

struct GoogleBooksResponse: Decodable {
    let items: [GoogleBookItem]?
}

struct GoogleBookItem: Decodable, Identifiable {
    let id: String
    let volumeInfo: VolumeInfo

    struct VolumeInfo: Decodable {
        let title: String
        let authors: [String]?
        let pageCount: Int?
        let imageLinks: ImageLinks?
        let description: String?

        struct ImageLinks: Decodable {
            let thumbnail: String?
            let smallThumbnail: String?
        }
    }

    var authorDisplay: String {
        volumeInfo.authors?.first ?? "Unknown Author"
    }

    var coverURL: String? {
        guard var urlString = volumeInfo.imageLinks?.thumbnail ?? volumeInfo.imageLinks?.smallThumbnail else {
            return nil
        }
        // Google returns http URLs; switch to https
        if urlString.hasPrefix("http://") {
            urlString = "https://" + urlString.dropFirst(7)
        }
        return urlString
    }

    var pageCount: Int {
        volumeInfo.pageCount ?? 0
    }
}

actor BookSearchService {
    private let session = URLSession.shared
    private let baseURL = "https://www.googleapis.com/books/v1/volumes"

    func search(query: String, limit: Int = 20) async throws -> [GoogleBookItem] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }

        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "q", value: trimmed),
            URLQueryItem(name: "maxResults", value: String(min(limit, 40)))
        ]

        guard let url = components.url else { return [] }

        let (data, _) = try await session.data(from: url)
        let result = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
        return result.items ?? []
    }
}
