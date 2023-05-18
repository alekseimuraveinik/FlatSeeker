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
    
    private var messageGroups = [Int: PythonObject]()
    private let images = CurrentValueSubject<[(Int, Data)], Never>([])
    private var loadingCancellable: AnyCancellable?
    
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
        await interactor.execute { python, getValue, asyncCall in
            let pythonMessageGroups = getValue(.client).get_message_groups()
            asyncCall {
                Task {
                    self.messageGroups = await self.interactor.isolate(pythonMessageGroups) { pythonMessageGroups, getValue in
                        pythonMessageGroups.reduce(into: self.messageGroups) { dict, group in
                            if let groupId = Int(group.grouped_id) {
                                dict[groupId] = group.messages
                            }
                        }
                    }
                }
            }
            asyncCall {
                Task {
                    let imageData = await self.interactor.isolate(pythonMessageGroups) { pythonMessageGroups, getValue in
                        let script = getValue(.script)
                        let messages = pythonMessageGroups.reduce([]) { total, group in
                            total + group.messages
                        }
                        return script.download_images(messages).compactMap { tuple in
                            tuple[1].bytes.flatMap { bytes in
                                (Int(tuple[0])!, bytes.data)
                            }
                        }
                    }
                    let previousValue = self.images.value
                    self.images.send(previousValue + imageData)
                }
            }
            let thumbnails = getValue(.script).download_small_images(pythonMessageGroups.map { $0.text_message })
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
