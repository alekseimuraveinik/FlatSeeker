import Foundation
import PythonKit

class TelegramClient {
    private let script: PythonObject
    private let client: PythonObject
    
    init?(config: TelegramClientConfig) {
        let scriptURL = config.scriptURL
        let scriptName = String(scriptURL.lastPathComponent.split(separator: ".")[0])
        let scriptDirectory = scriptURL.deletingLastPathComponent().path

        let sys = Python.import("sys")
        sys.path.append(scriptDirectory)
        
        script = Python.import(scriptName)
        client = script.start_client(config.sessionPath)
        
        if client == Python.None {
            return nil
        }
    }
    
    func getMessages() -> [MessageGroup] {
        let pythonMessages = script.get_messages(client)
        let messages = Array(pythonMessages).filter { $0.grouped_id != Python.None }
        
        let groupedId = messages.first!.grouped_id
        var textMessage = messages.first!.message
        var photoMessages = [PythonObject]()
        
        for message in messages {
            if message.grouped_id != groupedId {
                break
            }
            
            photoMessages.append(message)
            textMessage = message
        }
        
        let message = String(textMessage.message)!
        
        let images = script.download_photos(photoMessages)
        
        return [
            MessageGroup(
                message: message,
                photos: images.data
            )
        ]
    }
}
