import Combine
import UIKit

class PagerViewModel: ObservableObject {
    @Published var uiImages = [UIImage]()
    private let client: TelegramClient
    private let groupId: Int
    private var cancellable: AnyCancellable?
    
    private let loadingFinished: (() -> Void)?
    
    init(
        client: TelegramClient,
        groupId: Int,
        loadingFinished: (() -> Void)? = nil
    ) {
        self.client = client
        self.groupId = groupId
        self.loadingFinished = loadingFinished
        runFirstImage()
    }
    
    private func runFirstImage() {
        cancellable = client.loadFirstImage(groupId: groupId)
            .map(\.uiImages)
            .receive(on: RunLoop.main)
            .sink { [weak self] uiImages in
                self?.uiImages = uiImages
                self?.runAllImages()
            }
    }
    
    private func runAllImages() {
        cancellable = client.loadImages(groupId: groupId)
            .map(\.uiImages)
            .receive(on: RunLoop.main)
            .sink { [weak self] uiImages in
                self?.uiImages = uiImages
                self?.loadingFinished?()
            }
    }
}
