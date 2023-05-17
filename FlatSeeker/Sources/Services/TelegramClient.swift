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
        let pythonMessageGroups = client.get_message_groups()
        let messageGroups = Array(pythonMessageGroups)
        
        return messageGroups.compactMap { group in
            String(group.text_message).flatMap {
                MessageGroup(
                    message: $0,
                    photos: group.images.data.reversed()
                )
            }
        }
    }
}
