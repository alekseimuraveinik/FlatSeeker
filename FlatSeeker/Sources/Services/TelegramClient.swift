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
    private let images = CurrentValueSubject<[Int: [Data]], Never>([:])
    private let imagesAccessQueue = DispatchQueue(label: "imagesAccessQueue")
    
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
        await interactor.execute { _, getValue, _ in
            let client = getValue(.client)
            let pythonMessageGroups = client.get_message_groups()
            return pythonMessageGroups
                .enumerated()
                .map { index, group in
                    let district = String(group.district)!
                    let price = String(group.price)!
                    let thumbnail = group.thumbnail.bytes?.data ?? Data()
                    let images = Array(group.images).map { URL(string: String($0)!)! }
                    return MessageGroup(
                        id: Int(group.grouped_id)!,
                        textMessage: String(group.text_message.message)!,
                        district: district.isEmpty ? nil : district,
                        price: price.isEmpty ? nil : price,
                        thumbnail: thumbnail,
                        images: images.reversed()
                    )
                }
        }
    }
}
