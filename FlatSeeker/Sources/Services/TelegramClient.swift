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
        await interactor.execute { [images, imagesAccessQueue] python, getValue, asyncCall in
            let script = getValue(.script)
            let pythonMessageGroups = getValue(.client).get_message_groups()
            asyncCall {
                let imageGroups = script.download_images(pythonMessageGroups)
                let entries = imageGroups.map { group in
                    let id = Int(group.grouped_id)!
                    let images = Array(group.images)
                    return (id, Array(images.compactMap(\.bytes?.data).reversed()))
                }
                imagesAccessQueue.async {
                    var mutable = images.value
                    for entry in entries {
                        mutable[entry.0] = entry.1
                    }
                    images.send(mutable)
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
            .compactMap { $0[groupId] }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    func loadBestImages(groupId: Int) async {
        let entries = await interactor.execute { python, getValue, asyncCall in
            let client = getValue(.client)
            let imageGroups = client.download_images(groupId)
            return imageGroups.map { group in
                let id = Int(group.grouped_id)!
                let images = Array(group.images)
                return (id, Array(images.compactMap(\.bytes?.data).reversed()))
            }
        }
        imagesAccessQueue.async { [images] in
            var mutable = images.value
            for entry in entries {
                mutable[entry.0] = entry.1
            }
            images.send(mutable)
        }
    }
}
