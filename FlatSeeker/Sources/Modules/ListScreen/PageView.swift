import Combine
import SwiftUI

class PagerViewModel: ObservableObject {
    @Published var uiImages = [UIImage]()
    private var cancellable: AnyCancellable?
    
    init(client: TelegramClient, groupId: Int) {
        cancellable = client.loadImages(groupId: groupId)
            .map(\.uiImages)
            .receive(on: RunLoop.main)
            .sink { [weak self] uiImages in
                withAnimation {
                    self?.uiImages = uiImages
                }
            }
    }
}


struct PagerView: View {
    @ObservedObject var viewModel: PagerViewModel
    
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
