import Combine
import Foundation
import PythonKit
import PythonRuntime

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

class TelegramClient: PythonInteractor<TelegramClientStorageKey> {
    init(proof: PythonRuntime.Proof, config: TelegramClientConfig) {
        super.init(proof: proof, scriptURL: config.scriptURL) { script, key in
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
    
    func getGroups() async -> [(Int, String, String?, String?, [(Int, Data)])] {
        await execute(accessing: .client) { client in
            client.get_message_groups().compactMap { group in
                guard let id = Int(group.grouped_id),
                      let text = String(group.text)
                else {
                    return nil
                }
                
                let price = String(group.price)
                let district = String(group.district)
                let images = Array(group.images).compactMap { tuple in
                    if let messageId = Int(tuple[0]), let thumbnail = PythonBytes(tuple[1])?.data {
                        return (messageId, thumbnail)
                    }
                    return nil
                }
                return (id, text, price, district, images)
            }
        }
    }
}
