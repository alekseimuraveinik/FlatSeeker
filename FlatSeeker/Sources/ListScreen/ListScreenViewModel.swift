import Combine
import FlatSeekerCore
import Foundation
import PythonRuntime
import UIKit

class ListScreenViewModel: ObservableObject {
    @Published private (set) var text: String = "Initializing"
    @Published private (set) var photos: [UIImage] = []
    @Published var code: String = ""
    
    private var client: Client?
    
    func onAppear() {
        let client = Client(apiId: apiId, apiHash: apiHash, phoneNumber: "+995555993502")
        self.client = client
        if client.isInitiallyAuthorized {
            fetchMessages()
        }
    }
    
    func signIn() {
        guard let client else {
            assertionFailure("Client is nil")
            return
        }
        
        client.signIn(code: code)
        fetchMessages()
    }
    
    private func fetchMessages() {
        guard let client else {
            assertionFailure("Client is nil")
            return
        }
        
        let start = CFAbsoluteTimeGetCurrent()
        let messageGroups = client.getMessages(chatId: chatId, limit: 20)
        let diff = CFAbsoluteTimeGetCurrent() - start
        print("Took \(diff) seconds")

        guard let group = messageGroups.first else {
            assertionFailure("No message groups")
            return
        }

        text = group.message
        photos = group.photos.map { UIImage(data: $0)! }
    }
}

private let apiId = 15845540
private let apiHash = "4cb8ba1d05d513ed32a86f62fcd0e499"

private let chatId = -1001793067559
