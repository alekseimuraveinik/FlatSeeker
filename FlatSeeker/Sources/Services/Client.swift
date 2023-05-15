import Foundation
import PythonKit

class Client {
    private let script: PythonObject
    private let client: PythonObject
    
    init() {
        let scriptName = "swift-telegram-messages"
        
        let scriptURL = Bundle.main.url(forResource: scriptName, withExtension: "py")!
        let scriptDirectory = scriptURL.deletingLastPathComponent().path

        let sys = Python.import("sys")
        sys.path.append(scriptDirectory)
        
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sessionPath = documents.appendingPathComponent("session").path

        script = Python.import(scriptName)
        client = script.start_client(sessionPath)
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
        
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let groupFolder = documents.appendingPathComponent("\(Int(groupedId)!)")
        
        try! FileManager.default.createDirectory(
            atPath: groupFolder.path,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        let message = String(textMessage.message)!
        let urls = Array(script.download_photos(photoMessages, groupFolder.path))
        
        let dataArray = urls.map { pythonBytes in
            PythonBytes(pythonBytes)!.withUnsafeBytes({ unsafeRawBufferPointer in
                Data(unsafeRawBufferPointer)
            })
        }
        
        return [
            MessageGroup(message: message, photos: dataArray)
        ]
    }
}

struct MessageGroup {
    let message: String
    let photos: [Data]
}
