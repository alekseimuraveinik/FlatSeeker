import Combine
import Foundation
import PythonRuntime
import UIKit

class ListScreenViewModel: ObservableObject {
    @Published var text = ""
    @Published var pageViewModel: PagerViewModel
    
    private var isLoading = false
    private var client: TelegramClient
    private var messageGroups = [MessageGroup]()
    private var index = 0
    
    init(client: TelegramClient) {
        self.client = client
        self.pageViewModel = .init(client: client, groupId: 0)
    }
    
    func onAppear() {
        Task {
            await fetchMessages(client: client)
        }
    }
    
    func onNext() {
        Task {
            index += 1
            if index > messageGroups.count - 1 {
                await fetchMessages(client: client)
            } else {
                await displayMessages()
            }
        }
        
    }
    
    private func fetchMessages(client: TelegramClient) async {
        if isLoading {
            return
        }
        isLoading = true
        
        let messageGroups = client.getMessages()
        await MainActor.run {
            self.messageGroups = self.messageGroups + messageGroups
            isLoading = false
            displayMessages()
        }
    }
    
    @MainActor
    private func displayMessages() {
        if messageGroups.isEmpty {
            return
        }
        
        let group = messageGroups[index]
        text = group.textMessage
        pageViewModel = PagerViewModel(client: client, groupId: group.id)
    }
}
