import Foundation
import PythonRuntime
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    var client: TelegramClient!
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        initializePython()
        configureClient()
        return true
    }
}

// MARK: - Private
private extension AppDelegate {
    func initializePython() {
        let stdLibURL = Bundle.main.url(forResource: "python-stdlib", withExtension: nil)!
        let pipsURL = Bundle.main.url(forResource: "pips", withExtension: nil)!
        PythonRuntime.initialize(stdLibURL: stdLibURL, pipsURL: pipsURL)
    }
    
    func configureClient() {
        guard let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
              let scriptURL = Bundle.main.url(forResource: "swift-telegram-messages", withExtension: "py")
        else {
            return
        }
        
        client = .init(
            config: TelegramClientConfig(
                scriptURL: scriptURL,
                sessionPath: documentDirectoryURL.appendingPathComponent("session").path,
                apiId: 15845540,
                apiHash: "4cb8ba1d05d513ed32a86f62fcd0e499",
                phoneNumber: "+995555993502",
                codeRequestURL: "http://localhost:8080",
                channelId: -1001793067559
            )
        )
    }
}
