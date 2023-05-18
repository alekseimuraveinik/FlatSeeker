import SwiftUI

class ListViewModel: ObservableObject {
    @Published var items = [ListItemViewModel]()
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
        let messageGroups = await client.getMessages()
        
        if messageGroups.isEmpty {
            Task {
                await fetchMessages()
            }
            return
        }
        
        await displayMessages(messageGroups: messageGroups)
    }
    
    @MainActor
    private func displayMessages(messageGroups: [MessageGroup]) {
        self.items = self.items + messageGroups.map { group in
            let carouselViewModel = CarouselViewModel(
                thumbnail: UIImage(data: group.thumbnail),
                images: group.images
            )
            return ListItemViewModel(group: group, carouselViewModel: carouselViewModel)
        }
    }
}

struct ListView: View {
    @ObservedObject var viewModel: ListViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 40) {
                    ForEach(viewModel.items) { itemViewModel in
                        ListItemView(viewModel: itemViewModel)
                            .overlay(alignment: .bottomTrailing) {
                                NavigationLink {
                                    DetailsView(viewModel: itemViewModel)
                                } label: {
                                    Text("Подробнее")
                                }
                            }
                    }
                    
                    Color.clear.onAppear(perform: viewModel.onAppear)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .onAppear(perform: viewModel.onAppear)
    }
}
