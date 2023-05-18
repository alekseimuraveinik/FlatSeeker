import Combine
import SwiftUI

class CarouselViewModel: ObservableObject {
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

struct CarouselView: View {
    @ObservedObject var viewModel: CarouselViewModel
    
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

