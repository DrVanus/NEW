import SwiftUI

struct AllCryptoNewsView: View {
    @EnvironmentObject var vm: CryptoNewsFeedViewModel

    @ViewBuilder
    private var content: some View {
        if vm.isLoading {
            ProgressView("Loading…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = vm.errorMessage {
            VStack(spacing: 16) {
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                Button("Retry") {
                    Task { await vm.loadPreviewNews() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        } else {
            List {
                ForEach(vm.articles) { article in
                    NavigationLink(destination: NewsWebView(url: article.url)) {
                        NewsRowView(article: article, compact: false)
                            .environmentObject(vm)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onAppear {
                        if article.id == vm.articles.last?.id {
                            Task { await vm.loadMoreNews() }
                        }
                    }
                }
                if vm.isLoadingPage {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(PlainListStyle())
        }
    }

    var body: some View {
        content
            .refreshable {
                await vm.loadPreviewNews()
            }
            .navigationTitle("Crypto News")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: BookmarksView()
                        .environmentObject(vm)) {
                        Image(systemName: "bookmark")
                            .foregroundColor(.yellow)
                    }
                }
            }
            .onAppear {
                Task {
                    await vm.loadPreviewNews()
                }
            }
            .accentColor(.white)
    }
}

struct AllCryptoNewsView_Previews: PreviewProvider {
    static var previews: some View {
        AllCryptoNewsView()
            .environmentObject(CryptoNewsFeedViewModel())
    }
}
