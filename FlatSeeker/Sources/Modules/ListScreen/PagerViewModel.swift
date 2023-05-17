import Combine
import UIKit

class PagerViewModel: ObservableObject {
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
