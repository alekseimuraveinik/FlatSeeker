import Combine
import Foundation
import PythonKit

class TelegramClient {
    private let script: PythonObject
    private let client: PythonObject
    
    private var messages = [Int: PythonObject]()
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
            15845540,
            "4cb8ba1d05d513ed32a86f62fcd0e499",
            "+995555993502",
            "http://localhost:8080",
            -1001793067559
        )
    }
    
    func getMessages() -> [MessageGroup] {
        let pythonMessageGroups = client.get_message_groups()
        
        messages = pythonMessageGroups.reduce(into: messages) { dict, group in
            for message in group.messages {
                if let messageId = Int(message.id) {
                    dict[messageId] = message
                }
            }
        }
        
        messageGroups = pythonMessageGroups.reduce(into: messageGroups) { dict, group in
            if let groupId = Int(group.grouped_id) {
                dict[groupId] = group.messages
            }
        }
        
        return pythonMessageGroups.compactMap { group in
            String(group.text_message).flatMap {
                MessageGroup(
                    textMessage: $0,
                    imageIds: group.messages.compactMap { Int($0.id) }
                )
            }
        }
    }
    
    func loadImages(imageIds: [Int]) -> AnyPublisher<[Data], Never> {
        if imageIds.isEmpty {
            return Just([]).eraseToAnyPublisher()
        }
        
        return Future { [script, messages] promise in
            DispatchQueue.global().async {
                let messages = imageIds.map { messages[$0] }
                let imageData = Array(script.download_images(messages).data.reversed())
                promise(.success(imageData))
            }
        }
        .eraseToAnyPublisher()
    }
}
