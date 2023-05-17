import Combine
import Foundation
import PythonRuntime
import UIKit

class ListScreenViewModel: ObservableObject {
    @Published var text = ""
    @Published var photos = [UIImage]()
    @Published var isLoading = false
    
    private var client: TelegramClient
    private var messageGroups = [MessageGroup]()
    private var index = 0
    
    init(client: TelegramClient) {
        self.client = client
    }
    
    func onAppear() {
        isLoading = true
        Task {
            await fetchMessages(client: client)
        }
    }
    
    func onNext() {
        if isLoading {
            return
        }
        
        index += 1
        if index > messageGroups.count - 1 {
            isLoading = true
            Task {
                await fetchMessages(client: client)
            }
        } else {
            displayMessages()
        }
    }
    
    private func fetchMessages(client: TelegramClient) async {
        let messageGroups = client.getMessages()
        await MainActor.run {
            self.messageGroups = self.messageGroups + messageGroups
            isLoading = false
            displayMessages()
        }
    }
    
    private func displayMessages() {
        if messageGroups.isEmpty {
            return
        }
        
        let group = messageGroups[index]
        photos = group.photos.uiImages
        text = group.message
    }
}
