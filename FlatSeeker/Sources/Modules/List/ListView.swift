import SwiftUI

class ListViewModel: ObservableObject {
    @Published var messageGroups = [(MessageGroup, ListItemImagesViewModel)]()
    let client: TelegramClient
    
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
        self.messageGroups = self.messageGroups + messageGroups.map { group in
            let imagesViewModel = ListItemImagesViewModel(
                thumbnail: UIImage(data: group.thumbnail),
                client: client,
                groupId: group.id
            )
            return (group, imagesViewModel)
        }
    }
}

struct ListView: View {
    @ObservedObject var viewModel: ListViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 40) {
                    ForEach(viewModel.messageGroups, id: \.0.id) { group, imagesViewModel in
                        let listItemViewModel = ListItemViewModel(
                            group: group,
                            imagesViewModel: imagesViewModel
                        )
                        NavigationLink {
                            DetailsView(viewModel: listItemViewModel)
                        } label: {
                            ListItemView(viewModel: listItemViewModel)
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

struct ListItemViewModel {
    let text: String
    let district: String?
    let price: String?
    let imagesViewModel: ListItemImagesViewModel
    
    init(group: MessageGroup, imagesViewModel: ListItemImagesViewModel) {
        text = group.textMessage
        district = group.district
        price = group.price
        self.imagesViewModel = imagesViewModel
    }
}

struct ListItemView: View {
    let viewModel: ListItemViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            ListItemImagesView(viewModel: viewModel.imagesViewModel)
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(16)
            
            if let district = viewModel.district {
                Text("Район: \(district)")
            }
            
            if let price = viewModel.price {
                Text("Цена: $\(price)")
            }
        }
    }
}


import Combine

class ListItemImagesViewModel: ObservableObject {
    @Published var uiImages: [UIImage]
    private var cancellable: AnyCancellable?
    
    init(thumbnail: UIImage?, client: TelegramClient, groupId: Int) {
        uiImages = [thumbnail].compactMap { $0 }
        cancellable = client.loadImages(groupId: groupId)
            .map(\.uiImages)
            .receive(on: RunLoop.main)
            .sink { [weak self] uiImages in
                self?.uiImages = uiImages
            }
    }
}

struct ListItemImagesView: View {
    @ObservedObject var viewModel: ListItemImagesViewModel
    
    var body: some View {
        if viewModel.uiImages.isEmpty {
            ProgressView()
        } else {
            TabView {
                ForEach(viewModel.uiImages, id: \.self) { uiImage in
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                }
            }
            .tabViewStyle(PageTabViewStyle())
        }
    }
}
