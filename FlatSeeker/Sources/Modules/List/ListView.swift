import SwiftUI

class ListViewModel: ObservableObject {
    @Published var items = [(Int, ListItemViewModel)]()
    private let client: TelegramClient
    
    init(client: TelegramClient) {
        self.client = client
    }
    
    func onAppear() {
        Task {
            await fetchMessages()
        }
    }
    
    private func fetchMessages() async {
        let messageGroups = await client.getPosts()
        
        if messageGroups.isEmpty {
            Task {
                await fetchMessages()
            }
            return
        }
        
        await displayMessages(messageGroups: messageGroups)
    }
    
    @MainActor
    private func displayMessages(messageGroups: [Post]) {
        let count = self.items.count
        self.items = self.items + messageGroups.enumerated().map { index, group in
            let carouselViewModel = CarouselViewModel(
                thumbnail: UIImage(data: group.thumbnail),
                images: group.images
            )
            return (index + count, ListItemViewModel(group: group, carouselViewModel: carouselViewModel))
        }
    }
}

struct ListView: View {
    @ObservedObject var viewModel: ListViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 40) {
                    ForEach(viewModel.items, id: \.0) { index, itemViewModel in
                        ListItemView(viewModel: itemViewModel)
                            .overlay(alignment: .bottomTrailing) {
                                NavigationLink {
                                    DetailsView(viewModel: itemViewModel)
                                } label: {
                                    Text("Подробнее")
                                }
                            }
                            .onAppear {
                                if viewModel.items.count - index == 10 {
                                    viewModel.onAppear()
                                }
                            }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .onAppear(perform: viewModel.onAppear)
    }
}
