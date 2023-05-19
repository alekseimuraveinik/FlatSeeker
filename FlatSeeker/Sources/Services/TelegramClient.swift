import Combine
import Foundation
import PythonKit

struct TelegramClientConfig {
    let scriptURL: URL
    let sessionPath: String
    let apiId: Int
    let apiHash: String
    let phoneNumber: String
    let codeRequestURL: String
    let channelId: Int
}

enum TelegramClientStorageKey: CaseIterable {
    case client
}

class TelegramClient {
    private let interactor: PythonInteractor<TelegramClientStorageKey>
    private let photoURLFetcher = PhotoURLFetcher()
    
    init(config: TelegramClientConfig) {
        interactor = PythonInteractor(scriptURL: config.scriptURL) { script, key in
            switch key {
                case .client:
                    return script.Client(
                        config.sessionPath,
                        config.apiId,
                        config.apiHash,
                        config.phoneNumber,
                        config.codeRequestURL,
                        config.channelId
                    )
            }
        }
    }
    
    func getPosts() async -> [Post] {
        let groups = await getGroups()
        
        return await withTaskGroup(of: Post.self) { [photoURLFetcher] taskGroup in
            for (id, text, thumbnail, messageIds) in groups {
                taskGroup.addTask {
                    let urls = await photoURLFetcher.fetchURLs(messageIds: messageIds)
                    return Post(
                        id: id,
                        textMessage: text,
                        district: nil,
                        price: nil,
                        thumbnail: thumbnail,
                        images: urls
                    )
                }
            }
            
            let result = await taskGroup.reduce(into: []) { result, group in
                result.append(group)
            }
            
            return result.sorted(by: { $0.id > $1.id })
        }
    }
    
    private func getGroups() async -> [(Int, String, Data, [Int])] {
        await interactor.execute(accessing: .client) { client in
            client.get_message_groups().compactMap { group in
                guard let id = Int(group.grouped_id),
                      let text = String(group.text),
                      let thumbnail = PythonBytes(group.thumbnail)?.data
                else {
                    return nil
                }
                
                let messageIds = Array(group.image_ids).compactMap { Int($0) }
                return (id, text, thumbnail, messageIds)
            }
        }
    }
}
