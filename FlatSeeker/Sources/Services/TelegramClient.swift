import Foundation
import PythonKit

class TelegramClient {
    private let script: PythonObject
    private let client: PythonObject
    
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
        let pythonMessages = client.get_messages()
        let messages = Array(pythonMessages).filter { $0.grouped_id != Python.None }
        
        let dict = Dictionary(grouping: messages) { message in
            message.grouped_id
        }
        
        let messageGroups = dict.compactMap { _, messages in
            if messages.contains(where: { $0.message != "" }) {
                return messages
            }
            return nil
        }
        
        return messageGroups.compactMap { photoMessages in
            guard let textMessage = photoMessages.first(where: { $0.message != "" }) else {
                return nil
            }
            
            let images = script.download_photos(photoMessages)
            return String(textMessage.message)
                .flatMap {
                    MessageGroup(
                        message: $0,
                        photos: images.data.reversed()
                    )
                }
        }
    }
}
