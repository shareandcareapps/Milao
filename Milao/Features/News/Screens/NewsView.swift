import SwiftUI

struct NewsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(NewsService.self) private var newsService
    @Environment(AuthService.self) private var auth
    @State private var selectedCategory: NewsFeedCategory? = nil
    @State private var showAdminEditor = false

    private var isDark: Bool { colorScheme == .dark }

    private var articles: [NewsArticle] { newsService.articles }
    private var pinnedArticles: [NewsArticle] { newsService.articles.filter(\.isPinned) }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 0) {
                    header
                    if !pinnedArticles.isEmpty { hotTopics }
                    if newsService.isLoading && newsService.articles.isEmpty {
                        ProgressView().padding(.top, 60)
                    } else if articles.isEmpty {
                        EmptyStateView(
                            icon: "newspaper",
                            title: "No news yet",
                            message: "Community updates and announcements will show up here."
                        )
                        .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(articles) { article in
                                NavigationLink { NewsDetailView(article: article) } label: {
                                    NewsFeedCard(article: article)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.screen)
                        .padding(.top, 18)
                        .padding(.bottom, 120)
                    }
                }
            }
            .background(Theme.Colors.background)
            .toolbar(.hidden, for: .navigationBar)
            .refreshable { await newsService.fetchAll(category: selectedCategory?.rawValue) }

            Button { showAdminEditor = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(width: 62, height: 62)
                    .background(LinearGradient(colors: Theme.Colors.primaryGradient, startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
                    .shadow(color: Theme.Colors.primary.opacity(0.28), radius: 18, x: 0, y: 10)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 24)
            .padding(.bottom, 112)
        }
        .sheet(isPresented: $showAdminEditor) { NavigationStack { AdminEditNewsView() } }
        .task { await newsService.fetchAll(category: selectedCategory?.rawValue) }
        .onChange(of: selectedCategory) { _, newValue in
            Task { await newsService.fetchAll(category: newValue?.rawValue) }
        }
        .onChange(of: showAdminEditor) { wasShowing, isShowing in
            if wasShowing && !isShowing {
                Task { await newsService.fetchAll(category: selectedCategory?.rawValue) }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("NEWS")
                        .font(.nunito(.black, size: 30))
                        .foregroundStyle(.white)
                    Text("Visa · Immigration · Policy")
                        .font(.inter(.bold, size: 14))
                        .tracking(1.3)
                        .foregroundStyle(.white.opacity(0.70))
                }
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(Theme.Colors.primary).frame(width: 8, height: 8)
                    Text("LIVE")
                        .font(.inter(.black, size: 13))
                        .tracking(1.3)
                        .foregroundStyle(Theme.Colors.primary)
                }
                .padding(.horizontal, 13)
                .frame(height: 34)
                .background(.white.opacity(0.14), in: Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(0.22), lineWidth: 1))
            }

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(NewsFeedCategory.allCasesWithAll) { category in
                        let active = selectedCategory == category.value
                        Button { selectedCategory = category.value } label: {
                            Label(category.title, systemImage: category.icon)
                                .font(.inter(.bold, size: 13))
                                .foregroundStyle(active ? .white : .white.opacity(0.75))
                                .padding(.horizontal, 13)
                                .frame(height: 38)
                                .background(active ? Theme.Colors.primary : Color.white.opacity(0.14), in: Capsule())
                                .overlay(Capsule().strokeBorder(Color.white.opacity(active ? 0 : 0.28), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.trailing, Theme.Spacing.screen)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, Theme.Spacing.screen)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background {
            Group {
                if isDark {
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "#171717"), location: 0),
                            .init(color: Color(hex: "#2B2B2B"), location: 1),
                        ],
                        startPoint: .bottom, endPoint: .top
                    )
                } else {
                    Color(hex: "#0A2463")
                }
            }
            .ignoresSafeArea(edges: .top)
        }
    }

    private var hotTopics: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(pinnedArticles) { article in
                    let kind = NewsFeedCategory(rawValue: article.category ?? "")
                    let color = kind?.gradient.first ?? Theme.Colors.newsAccent
                    Label(article.title, systemImage: kind?.icon ?? "pin.fill")
                        .font(.inter(.bold, size: 14))
                        .foregroundStyle(color)
                        .lineLimit(1)
                        .padding(.horizontal, 14)
                        .frame(height: 42)
                        .background(color.opacity(0.13), in: Capsule())
                        .overlay(Capsule().strokeBorder(color.opacity(0.24), lineWidth: 1))
                }
            }
            .padding(.horizontal, Theme.Spacing.screen)
            .padding(.vertical, 14)
        }
        .scrollIndicators(.hidden)
    }
}

private struct NewsFeedCard: View {
    let article: NewsArticle

    private var kind: NewsFeedCategory? { NewsFeedCategory(rawValue: article.category ?? "") }
    private var gradient: [Color] { kind?.gradient ?? [Theme.Colors.newsAccent, Theme.Colors.newsAccent] }
    private var categoryTitle: String { kind?.title ?? (article.category?.capitalized ?? "News") }
    private var categoryIcon: String { kind?.icon ?? "newspaper" }

    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(height: 82)
                .overlay(alignment: .center) {
                    HStack(spacing: 16) {
                        Image(systemName: categoryIcon)
                            .font(.system(size: 27, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.84))
                        Text(categoryTitle.uppercased())
                            .font(.inter(.black, size: 14))
                            .tracking(3)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .frame(height: 36)
                            .background(.white.opacity(0.24), in: Capsule())
                        Spacer()
                        Label("Milao News", systemImage: "globe")
                            .font(.inter(.bold, size: 14))
                            .foregroundStyle(.white.opacity(0.70))
                    }
                    .padding(.horizontal, 20)
                }

            VStack(alignment: .leading, spacing: 11) {
                Text(article.title)
                    .font(.inter(.black, size: 18))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(2)
                Text(article.summary ?? article.body)
                    .font(.inter(.regular, size: 15))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(2)
                    .lineSpacing(4)
                HStack {
                    Label(article.formattedDate, systemImage: "clock")
                        .font(.inter(.regular, size: 14))
                        .foregroundStyle(Theme.Colors.textLight)
                    Spacer()
                    Text("Read more →")
                        .font(.inter(.black, size: 16))
                        .foregroundStyle(gradient.first ?? Theme.Colors.newsAccent)
                }
            }
            .padding(16)
        }
        .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Theme.Colors.shadow, radius: 12, x: 0, y: 4)
    }
}

private enum NewsFeedCategory: String, CaseIterable, Identifiable {
    case visa, immigration, policy, work, community
    var id: String { rawValue }
    var title: String { switch self { case .visa: "Visa"; case .immigration: "Immigration"; case .policy: "Policy"; case .work: "Work Auth"; case .community: "Community" } }
    var icon: String { switch self { case .visa: "doc.text"; case .immigration: "airplane"; case .policy: "checkmark.shield"; case .work: "briefcase"; case .community: "person.3" } }
    var gradient: [Color] { switch self { case .visa: [Color(hex: "#0099FF"), Color(hex: "#0055CC")]; case .immigration: [Color(hex: "#00C48C"), Color(hex: "#007A5E")]; case .policy: [Color(hex: "#9B59B6"), Color(hex: "#6C3483")]; case .work: [Color(hex: "#F4A833"), Color(hex: "#E68A00")]; case .community: [Color(hex: "#E8185C"), Color(hex: "#C0134A")] } }

    static var allCasesWithAll: [NewsFeedCategoryFilter] {
        [NewsFeedCategoryFilter(title: "All", icon: "square.grid.3x3", value: nil)] + Self.allCases.map { NewsFeedCategoryFilter(title: $0.title, icon: $0.icon, value: $0) }
    }
}

private struct NewsFeedCategoryFilter: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let value: NewsFeedCategory?
}

struct NewsDetailView: View {
    let article: NewsArticle
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text((article.category ?? "News").uppercased()).font(.inter(.black, size: 12)).foregroundStyle(Theme.Colors.newsAccent)
                Text(article.title).font(.nunito(.black, size: 30)).foregroundStyle(Theme.Colors.textPrimary)
                Text(article.body).font(.inter(.regular, size: 17)).foregroundStyle(Theme.Colors.textSecondary).lineSpacing(6)
            }.padding(Theme.Spacing.screen)
        }.background(Theme.Colors.background).navigationTitle("Article").navigationBarTitleDisplayMode(.inline)
    }
}

struct AdminEditNewsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(NewsService.self) private var newsService
    @Environment(AuthService.self) private var auth
    @State private var title = ""
    @State private var category = "visa"
    @State private var summary = ""
    @State private var articleBody = ""
    @State private var isPublishing = false
    var body: some View {
        Form {
            Section("Article") { TextField("Title", text: $title); TextField("Category", text: $category) }
            Section("Summary") { TextEditor(text: $summary).frame(minHeight: 90) }
            Section("Body") { TextEditor(text: $articleBody).frame(minHeight: 160) }
        }
        .navigationTitle("Edit News")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Publish") { Task { await publish() } }
                    .disabled(title.isEmpty || articleBody.isEmpty || isPublishing)
            }
        }
    }

    private func publish() async {
        guard let userId = auth.currentUser?.id else { return }
        isPublishing = true
        defer { isPublishing = false }
        _ = try? await newsService.create(
            title: title, summary: summary, body: articleBody,
            category: category, author: auth.currentUser?.fullName ?? "Milao News",
            isPinned: false, userId: userId
        )
        dismiss()
    }
}

#Preview { NavigationStack { NewsView() } }
