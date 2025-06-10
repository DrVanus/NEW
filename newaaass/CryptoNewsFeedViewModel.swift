import SwiftUI
import Foundation

@MainActor
final class CryptoNewsFeedViewModel: ObservableObject {
    @Published var articles: [CryptoNewsArticle] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingPage: Bool = false
    private var currentPage: Int = 1
    @Published var errorMessage: String?

    private let newsService = CryptoNewsService()

    init() {
        Task { await loadPreviewNews() }
        // Load any saved bookmarks from UserDefaults
        loadBookmarks()
    }

    @MainActor
    func loadPreviewNews() async {
        isLoading = true
        currentPage = 1
        defer { isLoading = false }

        do {
            let fetched = try await newsService.fetchPreviewNews()
            articles = fetched
            if fetched.isEmpty {
                errorMessage = "No news available"
            } else {
                errorMessage = nil
            }
        } catch {
            articles = []
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func loadMoreNews() async {
        guard !isLoadingPage else { return }
        isLoadingPage = true
        defer { isLoadingPage = false }

        currentPage += 1
        do {
            // Ensure your service has a paginated fetch method
            let fetched = try await newsService.fetchNews(page: currentPage)
            articles.append(contentsOf: fetched)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Track read/bookmarked articles
    @Published private var readArticleIDs: Set<UUID> = []
    @Published private var bookmarkedArticleIDs: Set<UUID> = []

    /// Persistence key for saved bookmarks
    private let bookmarksKey = "bookmarkedArticleIDs"

    // MARK: - Read / Bookmark Actions

    func toggleRead(_ article: CryptoNewsArticle) {
        if isRead(article) {
            readArticleIDs.remove(article.id)
        } else {
            readArticleIDs.insert(article.id)
        }
    }

    func isRead(_ article: CryptoNewsArticle) -> Bool {
        readArticleIDs.contains(article.id)
    }

    func toggleBookmark(_ article: CryptoNewsArticle) {
        if isBookmarked(article) {
            bookmarkedArticleIDs.remove(article.id)
        } else {
            bookmarkedArticleIDs.insert(article.id)
        }
        // Persist the change
        saveBookmarks()
    }

    func isBookmarked(_ article: CryptoNewsArticle) -> Bool {
        bookmarkedArticleIDs.contains(article.id)
    }

    /// Load bookmarked IDs from UserDefaults
    private func loadBookmarks() {
        if let saved = UserDefaults.standard.array(forKey: bookmarksKey) as? [String] {
            bookmarkedArticleIDs = Set(saved.compactMap { UUID(uuidString: $0) })
        }
    }

    /// Save current bookmarked IDs to UserDefaults
    private func saveBookmarks() {
        let ids = bookmarkedArticleIDs.map { $0.uuidString }
        UserDefaults.standard.set(ids, forKey: bookmarksKey)
    }
}
