import Combine
import Core
import Foundation
import PythonRuntime

class ListScreenViewModel: ObservableObject {
    @Published private (set) var text: String = "Initializing"
    @Published private (set) var photos: [URL] = []
    @Published var code: String = ""
    
    private var client: Client?
    
    func onAppear() {
        Task {
            let path = Bundle.main.path(forResource: "python-stdlib", ofType: nil)!
            PythonRuntime.initialize(stdlibPath: path)
            
            let client = Client(apiId: apiId, apiHash: apiHash, phoneNumber: "+995555993502")
            self.client = client
            if client.isInitiallyAuthorized {
                fetchMessages()
            }
        }
    }
    
    func signIn() {
        guard let client else {
            assertionFailure("Client is nil")
            return
        }
        
        Task {
            client.signIn(code: code)
            fetchMessages()
        }
    }
    
    private func fetchMessages() {
        guard let client else {
            assertionFailure("Client is nil")
            return
        }
        
        Task {
            let messageGroups = await client.getMessages(chatId: chatId, limit: 20)

            guard let group = messageGroups.first else {
                print("No message groups")
                return
            }

            await MainActor.run {
                text = group.message
                photos = group.photos
            }
        }
    }
}

private let apiId = 15845540
private let apiHash = "4cb8ba1d05d513ed32a86f62fcd0e499"

private let chatId = -1001793067559
