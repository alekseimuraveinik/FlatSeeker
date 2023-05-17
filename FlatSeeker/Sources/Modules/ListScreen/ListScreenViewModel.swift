import Combine
import Foundation
import PythonRuntime
import UIKit

class ListScreenViewModel: ObservableObject {
    @Published var text = ""
    @Published var district: String?
    @Published var price: String?
    @Published var pageViewModel: PagerViewModel
    
    private var client: TelegramClient
    private var messageGroups = [MessageGroup]()
    private var index = -1
    
    init(client: TelegramClient) {
        self.client = client
        self.pageViewModel = .init(thumbnail: .init(), client: client, groupId: 0)
    }
    
    func onAppear() {
        Task {
            await fetchMessages()
        }
    }
    
    func onNext() {
        if index >= messageGroups.count - 5 {
            Task {
                await fetchMessages()
            }
        }
        
        Task {
            await displayMessages()
        }
    }
    
    private func fetchMessages() async {
        let messageGroups = client.getMessages()
        guard !messageGroups.isEmpty else { return }
        await MainActor.run {
            self.messageGroups = self.messageGroups + messageGroups
            displayMessages()
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
        
        if index >= messageGroups.count - 1 {
            return
        }
        index += 1
        
        let group = messageGroups[index]
        text = group.textMessage
        district = group.district
        price = group.price
        
        pageViewModel = PagerViewModel(
            thumbnail: UIImage(data: group.thumbnail),
            client: client,
            groupId: group.id
        )
    }
}
