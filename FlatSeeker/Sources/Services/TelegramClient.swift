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
    private let images = CurrentValueSubject<[(Int, Data)], Never>([])
    private var loadingCancellable: AnyCancellable?
    
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
        guard loadingCancellable == nil else {
            return []
        }
        
        let pythonMessageGroups = client.get_message_groups()
        
        defer {
            loadFullImages(pythonMessageGroups: pythonMessageGroups)
        }
        
        messageGroups = pythonMessageGroups.reduce(into: messageGroups) { dict, group in
            if let groupId = Int(group.grouped_id) {
                dict[groupId] = group.messages
            }
        }
        
        let thumbnails = script.download_small_images(pythonMessageGroups.map { $0.text_message })
        
        return pythonMessageGroups
            .enumerated()
            .map { index, group in
                let district = String(group.district)!
                let price = String(group.price)!
                return MessageGroup(
                    id: Int(group.grouped_id)!,
                    textMessage: String(group.text_message.message)!,
                    district: district.isEmpty ? nil : district,
                    price: price.isEmpty ? nil : price,
                    thumbnail: thumbnails[index].bytes?.data ?? Data()
                )
            }
    }
    
    private func loadFullImages(pythonMessageGroups: PythonObject) {
        loadingCancellable = Future<[(Int, Data)], Never> { [script, pythonMessageGroups] promise in
            DispatchQueue.global().async {
                let messages = pythonMessageGroups.reduce([]) { total, group in
                    total + group.messages
                }
                let imageData = script.download_images(messages).compactMap { tuple in
                    tuple[1].bytes.flatMap { bytes in
                        (Int(tuple[0])!, bytes.data)
                    }
                }
                promise(.success(imageData.reversed()))
            }
        }
        .sink { [weak self, images] newValue in
            let previousValue = images.value
            images.send(previousValue + newValue)
            self?.loadingCancellable = nil
        }
    }
    
    func loadImages(groupId: Int) -> AnyPublisher<[Data], Never> {
        images
            .map { pairs in
                pairs.filter { $0.0 == groupId}.map { $0.1 }
            }
            .filter { !$0.isEmpty }
            .eraseToAnyPublisher()
    }
}
