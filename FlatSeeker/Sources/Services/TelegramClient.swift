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

enum TelegramClientStorageKey {
    case script
    case client
}

class TelegramClient {
    private let interactor: PythonInteractor<TelegramClientStorageKey>
    private let photoURLFetcher = PhotoURLFetcher()
    
    init(config: TelegramClientConfig) {
        let scriptURL = config.scriptURL
        let scriptName = String(scriptURL.lastPathComponent.split(separator: ".")[0])

        interactor = PythonInteractor(script: scriptURL) { storage, python in
            let script = python.import(scriptName)
            let client = script.Client(
                config.sessionPath,
                config.apiId,
                config.apiHash,
                config.phoneNumber,
                config.codeRequestURL,
                config.channelId
            )
            storage[.script] = script
            storage[.client] = client
        }
    }
    
    func getMessages() async -> [MessageGroup] {
        let groups = await interactor.execute { _, getValue in
            let client = getValue(.client)
            let pythonMessageGroups = client.get_message_groups()
            return pythonMessageGroups
                .map { group in
                    let text = String(group.text)!
                    let district = String(group.district)!
                    let price = String(group.price)!
                    let thumbnail = group.thumbnail.bytes?.data ?? Data()
                    let messageIds = Array(group.image_ids).map { Int($0)! }
                    return (text, district, price, thumbnail, messageIds)
                }
        }
        
        return await withTaskGroup(of: (Int, MessageGroup).self) { [photoURLFetcher] taskGroup in
            for (groupIndex, group) in groups.enumerated() {
                let (text, district, price, thumbnail, messageIds) = group
                
                taskGroup.addTask {
                    let urls = await photoURLFetcher.fetchURLs(messageIds: messageIds)
                    return (
                        groupIndex,
                        MessageGroup(
                            textMessage: text,
                            district: district.isEmpty ? nil : district,
                            price: price.isEmpty ? nil : price,
                            thumbnail: thumbnail,
                            images: urls
                        )
                    )
                }
            }
            
            let result = await taskGroup.reduce(into: []) { result, group in
                result.append(group)
            }
            
            return result.sorted(by: { $0.0 < $1.0 }).map(\.1)
        }
    }
}
