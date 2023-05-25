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
    
    func getGroups() async -> [(Int, Date, Int, String, [Data])] {
        await execute(accessing: .client) { client in
            client.get_message_groups().compactMap { group in
                guard let id = Int(group.message_id),
                      let authourId = Int(group.author_id),
                      let text = String(group.text),
                      let dateInt = Double(group.date)
                else {
                    return nil
                }
                
                let date =  Date(timeIntervalSince1970: dateInt)
                let thumbnails = Array(group.thumbnails).compactMap { PythonBytes($0)?.data }
                return (id, date, authourId, text, thumbnails)
            }
        }
    }
}
