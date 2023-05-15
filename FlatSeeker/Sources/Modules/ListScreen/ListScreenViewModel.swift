import Combine
import FlatSeekerCore
import Foundation
import PythonRuntime
import UIKit

class ListScreenViewModel: ObservableObject {
    @Published private (set) var text: String = "Загрузка"
    @Published private (set) var photos: [UIImage] = []
    @Published private (set) var isLoading = false
    
    private let client: Client
    
    init(client: Client) {
        self.client = client
    }
    
    func onAppear() {
        isLoading = true
        Task {
            await fetchMessages()
        }
    }
    
    private func fetchMessages() async {
        let messageGroups = client.getMessages()

        if let group = messageGroups.first {
            await MainActor.run {
                isLoading = false
                text = group.message
                photos = group.photos.map { UIImage(data: $0)! }
            }
        }
    }
}
