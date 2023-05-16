import Combine
import FlatSeekerCore
import Foundation
import PythonRuntime
import UIKit

class ListScreenViewModel: ObservableObject {
    @Published private (set) var text: String = "Загрузка"
    @Published private (set) var photos: [UIImage] = []
    @Published private (set) var isLoading = false
    
    private var client: TelegramClient?
    
    init(client: TelegramClient?) {
        self.client = client
        if client == nil {
            isLoading = false
            text = "Не удалось авторизоватьтся"
        }
    }
    
    func onAppear() {
        guard let client else { return }
        isLoading = true
        Task {
            await fetchMessages(client: client)
        }
    }
    
    private func fetchMessages(client: TelegramClient) async {
        let messageGroups = client.getMessages()

        if let group = messageGroups.first {
            await MainActor.run {
                isLoading = false
                text = group.message
                photos = group.photos.uiImages
            }
        }
    }
}
