import Combine
import SwiftUI

class PageViewModel: ObservableObject {
    @Published var uiImages = [UIImage]()
    private var cancellable: AnyCancellable?
    
    init(client: TelegramClient, imageIds: [Int]) {
        cancellable = client.loadImages(imageIds: imageIds)
            .map(\.uiImages)
            .receive(on: RunLoop.main)
            .sink { [weak self] uiImages in
                withAnimation {
                    self?.uiImages = uiImages
                }
            }
    }
}


struct PageView: View {
    @ObservedObject var viewModel: PageViewModel
    
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
            .transition(.opacity)
        }
    }
}
