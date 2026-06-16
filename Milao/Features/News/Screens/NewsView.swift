import SwiftUI

struct NewsView: View {
    @State private var selectedCategory: NewsCategory? = nil
    @State private var showAdminEditor = false

    private var articles: [NewsArticleSample] {
        NewsArticleSample.samples.filter { selectedCategory == nil || $0.category == selectedCategory }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 0) {
                    header
                    hotTopics
                    LazyVStack(spacing: 14) {
                        ForEach(articles) { article in
                            NavigationLink { NewsDetailView(article: article.communityArticle) } label: {
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
            .background(Theme.Colors.background)
            .toolbar(.hidden, for: .navigationBar)

            Button { showAdminEditor = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(.white)
                    .frame(width: 62, height: 62)
                    .background(LinearGradient(colors: Theme.Colors.primaryGradient, startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
                    .shadow(color: Theme.Colors.primary.opacity(0.30), radius: 18, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 24)
            .padding(.bottom, 112)
        }
        .sheet(isPresented: $showAdminEditor) { NavigationStack { AdminEditNewsView() } }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("NEWS")
                        .font(.nunito(.black, size: 30))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("Visa · Immigration · Policy")
                        .font(.inter(.bold, size: 13))
                        .tracking(1.3)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(Theme.Colors.primary).frame(width: 8, height: 8)
                    Text("LIVE")
                        .font(.inter(.black, size: 14))
                        .tracking(1.3)
                        .foregroundStyle(Theme.Colors.primary)
                }
                .padding(.horizontal, 15)
                .frame(height: 38)
                .background(Theme.Colors.primary.opacity(0.10), in: Capsule())
                .overlay(Capsule().strokeBorder(Theme.Colors.primary.opacity(0.22), lineWidth: 1))
            }

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(NewsCategory.allCasesWithAll) { category in
                        let active = selectedCategory == category.value
                        Button { selectedCategory = category.value } label: {
                            Label(category.title, systemImage: category.icon)
                                .font(.inter(.bold, size: 14))
                                .foregroundStyle(active ? .white : Theme.Colors.textSecondary)
                                .padding(.horizontal, 15)
                                .frame(height: 44)
                                .background(active ? Theme.Colors.primary : Color.black.opacity(0.06), in: Capsule())
                                .overlay(Capsule().strokeBorder(Color.black.opacity(active ? 0 : 0.09), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.trailing, Theme.Spacing.screen)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, Theme.Spacing.screen)
        .padding(.top, 50)
        .padding(.bottom, 14)
        .background(LinearGradient(colors: Theme.Colors.headerGradientLight, startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    private var hotTopics: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(HotTopic.samples) { topic in
                    Label(topic.title, systemImage: topic.icon)
                        .font(.inter(.bold, size: 14))
                        .foregroundStyle(topic.color)
                        .padding(.horizontal, 14)
                        .frame(height: 42)
                        .background(topic.color.opacity(0.13), in: Capsule())
                        .overlay(Capsule().strokeBorder(topic.color.opacity(0.24), lineWidth: 1))
                }
            }
            .padding(.horizontal, Theme.Spacing.screen)
            .padding(.vertical, 14)
        }
        .scrollIndicators(.hidden)
    }
}

private struct NewsFeedCard: View {
    let article: NewsArticleSample

    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: article.category.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(height: 82)
                .overlay(alignment: .center) {
                    HStack(spacing: 16) {
                        Image(systemName: article.category.icon)
                            .font(.system(size: 27, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.84))
                        Text(article.category.title.uppercased())
                            .font(.inter(.black, size: 14))
                            .tracking(3)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .frame(height: 36)
                            .background(.white.opacity(0.24), in: Capsule())
                        Spacer()
                        Label("Milao News", systemImage: "globe")
                            .font(.inter(.bold, size: 13))
                            .foregroundStyle(.white.opacity(0.70))
                    }
                    .padding(.horizontal, 20)
                }

            VStack(alignment: .leading, spacing: 11) {
                Text(article.title)
                    .font(.inter(.black, size: 18))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(2)
                Text(article.body)
                    .font(.inter(.regular, size: 15))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(2)
                    .lineSpacing(4)
                HStack {
                    Label(article.date, systemImage: "clock")
                        .font(.inter(.regular, size: 14))
                        .foregroundStyle(Theme.Colors.textLight)
                    Spacer()
                    Text("Read more →")
                        .font(.inter(.black, size: 16))
                        .foregroundStyle(article.category.gradient.first ?? Theme.Colors.newsAccent)
                }
            }
            .padding(16)
        }
        .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Theme.Colors.shadow, radius: 12, x: 0, y: 4)
    }
}

private enum NewsCategory: String, CaseIterable, Identifiable {
    case visa, immigration, policy, work, community
    var id: String { rawValue }
    var title: String { switch self { case .visa: "Visa"; case .immigration: "Immigration"; case .policy: "Policy"; case .work: "Work Auth"; case .community: "Community" } }
    var icon: String { switch self { case .visa: "doc.text"; case .immigration: "airplane"; case .policy: "checkmark.shield"; case .work: "briefcase"; case .community: "person.3" } }
    var gradient: [Color] { switch self { case .visa: [Color(hex: "#0099FF"), Color(hex: "#0055CC")]; case .immigration: [Color(hex: "#00C48C"), Color(hex: "#007A5E")]; case .policy: [Color(hex: "#9B59B6"), Color(hex: "#6C3483")]; case .work: [Color(hex: "#F4A833"), Color(hex: "#E68A00")]; case .community: [Color(hex: "#E8185C"), Color(hex: "#C0134A")] } }

    static var allCasesWithAll: [NewsCategoryFilter] {
        [NewsCategoryFilter(title: "All", icon: "square.grid.3x3", value: nil)] + Self.allCases.map { NewsCategoryFilter(title: $0.title, icon: $0.icon, value: $0) }
    }
}

private struct NewsCategoryFilter: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let value: NewsCategory?
}

private struct HotTopic: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    static let samples = [
        HotTopic(title: "H-1B Updates", icon: "briefcase", color: Color(hex: "#0099FF")),
        HotTopic(title: "OPT/CPT", icon: "graduationcap", color: Color(hex: "#00C48C")),
        HotTopic(title: "Green Card", icon: "creditcard", color: Color(hex: "#9B59B6")),
        HotTopic(title: "Travel Ban", icon: "airplane", color: Theme.Colors.accent),
        HotTopic(title: "DACA", icon: "shield", color: Theme.Colors.saffron)
    ]
}

private struct NewsArticleSample: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let date: String
    let category: NewsCategory
    var communityArticle: CommunityArticle {
        CommunityArticle(title: title, category: category.title, author: "Milao News", date: date, readTime: "3 min", summary: body, body: body + "\n\nMore details are available from official immigration and community sources.", isPinned: false)
    }
    static let samples = [
        NewsArticleSample(title: "USCIS announces new OPT rules for STEM graduates", body: "The USCIS has announced important updates for international students on OPT. Students with STEM degrees should review timelines and employer requirements.", date: "Jun 3, 2026", category: .visa),
        NewsArticleSample(title: "H-1B lottery guidance for community members", body: "Employers and applicants should prepare documentation earlier this season as policy review windows tighten.", date: "Jun 8, 2026", category: .work),
        NewsArticleSample(title: "Local community legal clinic this weekend", body: "Volunteer attorneys will answer visa, green card, and work authorization questions at the community center.", date: "Jun 12, 2026", category: .community)
    ]
}

struct NewsDetailView: View {
    let article: CommunityArticle
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(article.category.uppercased()).font(.inter(.black, size: 12)).foregroundStyle(Theme.Colors.newsAccent)
                Text(article.title).font(.nunito(.black, size: 30)).foregroundStyle(Theme.Colors.textPrimary)
                Text(article.body).font(.inter(.regular, size: 17)).foregroundStyle(Theme.Colors.textSecondary).lineSpacing(6)
            }.padding(Theme.Spacing.screen)
        }.background(Theme.Colors.background).navigationTitle("Article").navigationBarTitleDisplayMode(.inline)
    }
}

struct AdminEditNewsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var category = "Visa"
    @State private var summary = ""
    @State private var articleBody = ""
    var body: some View {
        Form {
            Section("Article") { TextField("Title", text: $title); TextField("Category", text: $category) }
            Section("Summary") { TextEditor(text: $summary).frame(minHeight: 90) }
            Section("Body") { TextEditor(text: $articleBody).frame(minHeight: 160) }
        }
        .navigationTitle("Edit News")
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Publish") { dismiss() } } }
    }
}

#Preview { NavigationStack { NewsView() } }
