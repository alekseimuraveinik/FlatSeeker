import SwiftUI

class ListViewModel: ObservableObject {
    @Published private(set) var items = [ListItemViewModel]()
    private let postsRepository: PostsRepository
    
    init(postsRepository: PostsRepository) {
        self.postsRepository = postsRepository
    }
    
    func fetchPosts() {
        Task {
            let posts = await postsRepository.getPosts()
            await displayPosts(posts: posts)
        }
    }
    
    @MainActor
    private func displayPosts(posts: [PostDTO]) {
        let count = items.count
        let totalItems = items + posts.enumerated().map { [postsRepository] index, post in
            ListItemViewModel(
                index: count + index,
                post: post,
                carouselViewModel: CarouselViewModel(images: post.images),
                isInFavourite: postsRepository.getIsInFavourite(post: post),
                addToFavourite: { postsRepository.addToFavourite(post: post) },
                removeFromFavourite: { postsRepository.removeFromFavourite(post: post) }
            )
        }
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
                                if viewModel.items.count - itemViewModel.index == 10 {
                                    viewModel.fetchPosts()
                                }
                            }
                    }
                    
                    if !viewModel.items.isEmpty {
                        Color.clear.onAppear(perform: viewModel.fetchPosts)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .onAppear(perform: viewModel.fetchPosts)
    }
}
