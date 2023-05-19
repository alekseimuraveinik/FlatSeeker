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
    
    func getGroups() async -> [(Int, String, String?, String?, Data, [Int])] {
        await interactor.execute(accessing: .client) { client in
            client.get_message_groups().compactMap { group in
                guard let id = Int(group.grouped_id),
                      let text = String(group.text),
                      let thumbnail = PythonBytes(group.thumbnail)?.data
                else {
                    return nil
                }
                
                let price = String(group.price)
                let district = String(group.district)
                let messageIds = Array(group.image_ids).compactMap { Int($0) }
                return (id, text, price, district, thumbnail, messageIds)
            }
        }
    }
}
