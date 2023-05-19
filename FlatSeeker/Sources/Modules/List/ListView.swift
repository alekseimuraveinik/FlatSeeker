import SwiftUI

class ListViewModel: ObservableObject {
    @Published private(set) var items = [ListItemViewModel]()
    private let postsRepository: PostsRepository
    private var messagesFetchingItemId: Int?
    
    init(postsRepository: PostsRepository) {
        self.postsRepository = postsRepository
    }
    
    func didDisplayItem(id: Int) {
        if id == messagesFetchingItemId {
            fetchPosts()
        }
    }
    
    func fetchPosts() {
        Task {
            let posts = await postsRepository.getPosts()
            await displayPosts(posts: posts)
        }
    }
    
    @MainActor
    private func displayPosts(posts: [Post]) {
        let totalItems = items + posts.map { post in
            ListItemViewModel(
                post: post,
                carouselViewModel: CarouselViewModel(images: post.images)
            )
        }
        messagesFetchingItemId = totalItems[max(totalItems.count - 10, 0)].id
        items = totalItems
    }
}

struct ListView: View {
    @ObservedObject var viewModel: ListViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 40) {
                    ForEach(viewModel.items, id: \.id) { itemViewModel in
                        ListItemView(viewModel: itemViewModel)
                            .overlay(alignment: .bottomTrailing) {
                                NavigationLink {
                                    DetailsView(viewModel: itemViewModel)
                                } label: {
                                    Text("Подробнее")
                                }
                            }
                            .onAppear {
                                viewModel.didDisplayItem(id: itemViewModel.id)
                            }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .onAppear(perform: viewModel.fetchPosts)
    }
}
