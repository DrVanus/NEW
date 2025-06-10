//
//  CryptoNewsArticle.swift
//  CryptoSage
//
//  Created by DM on 5/26/25.
//


//
// CryptoNewsArticle.swift
// CryptoSage
//

import Foundation

/// Represents a single news article in the CryptoSage app.
struct CryptoNewsArticle: Codable, Identifiable, Equatable {
    /// Unique identifier for SwiftUI lists
    let id: UUID
    
    /// Headline of the article
    let title: String
    
    /// Optional subtitle or summary
    let description: String?
    
    /// Link to the full article
    let url: URL
    
    /// Optional URL to an image
    let urlToImage: URL?

    /// Name of the news source
    let sourceName: String
    
    /// Publication date
    let publishedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case url
        case urlToImage
        case publishedAt
        case sourceName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.url = try container.decode(URL.self, forKey: .url)
        self.urlToImage = try container.decodeIfPresent(URL.self, forKey: .urlToImage)
        self.sourceName = try container.decodeIfPresent(String.self, forKey: .sourceName) ?? "Unknown Source"
        let dateString = try container.decode(String.self, forKey: .publishedAt)
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .publishedAt,
                in: container,
                debugDescription: "Date string does not match ISO8601 format: \(dateString)"
            )
        }
        self.publishedAt = date
    }
    
    /// Provides a default UUID when decoding or initializing
    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        url: URL,
        urlToImage: URL? = nil,
        sourceName: String = "Unknown Source",
        publishedAt: Date
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.url = url
        self.urlToImage = urlToImage
        self.sourceName = sourceName
        self.publishedAt = publishedAt
    }

    /// Returns a relative time like "1d, 7h", "7h, 26m", or "45m"
    var relativeTime: String {
        let interval = Date().timeIntervalSince(publishedAt)
        let totalMinutes = max(Int(interval / 60), 0)
        if totalMinutes < 60 {
            return "\(totalMinutes)m"
        } else if totalMinutes < 1440 {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            return "\(hours)h, \(minutes)m"
        } else {
            let days = totalMinutes / 1440
            let hours = (totalMinutes % 1440) / 60
            return "\(days)d, \(hours)h"
        }
    }
}
