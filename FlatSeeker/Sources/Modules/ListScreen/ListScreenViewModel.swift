import Combine
import Foundation
import PythonRuntime
import UIKit

class ListScreenViewModel: ObservableObject {
    @Published var text = ""
    @Published var district: String?
    @Published var price: String?
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
            await fetchMessages()
        }
    }
    
    func onNext() {
        Task {
            index += 1
            if index > messageGroups.count - 2 {
                await fetchMessages()
            } else {
                await displayMessages()
            }
        }
        
    }
    
    private func fetchMessages(preventive: Bool = false) async {
        if isLoading {
            return
        }
        isLoading = true
        
        let messageGroups = client.getMessages()
        await MainActor.run {
            self.messageGroups = self.messageGroups + messageGroups
            isLoading = false
            if !preventive {
                displayMessages()
            }
        }
    }
    
    @MainActor
    private func displayMessages() {
        if messageGroups.isEmpty {
            Task {
                await fetchMessages()
            }
            return
        }
        
        let group = messageGroups[index]
        text = group.textMessage
        district = group.district
        price = group.price
        
        let loadingFinished = { [weak self, index, messageGroups] in
            if index > messageGroups.count - 2 {
                Task {
                    await self?.fetchMessages(preventive: true)
                }
            }
        }
        
        pageViewModel = PagerViewModel(
            client: client,
            groupId: group.id,
            loadingFinished: loadingFinished
        )
    }
}
