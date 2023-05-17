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

class TelegramClient {
    private let script: PythonObject
    private let client: PythonObject
    
    private var messageGroups = [Int: PythonObject]()
    
    init(config: TelegramClientConfig) {
        let scriptURL = config.scriptURL
        let scriptName = String(scriptURL.lastPathComponent.split(separator: ".")[0])
        let scriptDirectory = scriptURL.deletingLastPathComponent().path

        let sys = Python.import("sys")
        sys.path.append(scriptDirectory)
        
        script = Python.import(scriptName)
        client = script.Client(
            config.sessionPath,
            config.apiId,
            config.apiHash,
            config.phoneNumber,
            config.codeRequestURL,
            config.channelId
        )
    }
    
    func getMessages() -> [MessageGroup] {
        let pythonMessageGroups = client.get_message_groups()
        
        messageGroups = pythonMessageGroups.reduce(into: messageGroups) { dict, group in
            if let groupId = Int(group.grouped_id) {
                dict[groupId] = group.messages
            }
        }
        
        return pythonMessageGroups.compactMap { group in
            let district = String(group.district)!
            let price = String(group.price)!
            return MessageGroup(
                id: Int(group.grouped_id)!,
                textMessage: String(group.text_message)!,
                district: district.isEmpty ? nil : district,
                price: price.isEmpty ? nil : price
            )
        }
    }
    
    func loadFirstImage(groupId: Int) -> AnyPublisher<[Data], Never> {
        guard messageGroups[groupId] != nil, let first = messageGroups[groupId]?[-1] else {
            return Just([]).eraseToAnyPublisher()
        }
        
        return Future { [script] promise in
            DispatchQueue.global().async {
                let imageData = script.download_small_image(first).bytes.data
                promise(.success([imageData]))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func loadImages(groupId: Int) -> AnyPublisher<[Data], Never> {
        guard messageGroups[groupId] != nil else {
            return Just([]).eraseToAnyPublisher()
        }
        
        return Future { [script, messageGroups] promise in
            DispatchQueue.global().async {
                let messages = messageGroups[groupId]
                let imageData = Array(script.download_images(messages).data.reversed())
                promise(.success(imageData))
            }
        }
        .eraseToAnyPublisher()
    }
}
