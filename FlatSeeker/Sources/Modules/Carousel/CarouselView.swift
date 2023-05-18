import Combine
import SwiftUI

class CarouselViewModel: ObservableObject {
    @Published var uiImages: [UIImage]
    
    private let client: TelegramClient
    private let groupId: Int
    private var bestImagesLoaded = false
    private var cancellable: AnyCancellable?
    
    init(thumbnail: UIImage?, client: TelegramClient, groupId: Int) {
        self.client = client
        self.groupId = groupId
        uiImages = [thumbnail].compactMap { $0 }
        cancellable = client.loadImages(groupId: groupId)
            .map(\.uiImages)
            .receive(on: RunLoop.main)
            .sink { [weak self] uiImages in
                self?.uiImages = uiImages
            }
    }
    
    func loadBestImages() {
        guard !bestImagesLoaded else { return }
        bestImagesLoaded = true
        client.loadBestImages(groupId: groupId)
    }
}

struct CarouselView: View {
    @ObservedObject var viewModel: CarouselViewModel
    
    var body: some View {
        if viewModel.uiImages.isEmpty {
            ProgressView()
        } else {
            TabView {
                ForEach(viewModel.uiImages, id: \.self) { uiImage in
                    GeometryReader { geometry in
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle())
        }
    }
}

