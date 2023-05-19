import Foundation
import PythonRuntime
import UIKit

class Container {
    private let telegramClient: TelegramClient
    private let photoURLFetcher: PhotoURLFetcher
    private let postsRepository: PostsRepository
    
    init(telegramClientConfig: TelegramClientConfig) {
        self.telegramClient = TelegramClient(config: telegramClientConfig)
        self.photoURLFetcher = PhotoURLFetcher()
        self.postsRepository = PostsRepository(
            telegramClient: telegramClient,
            photoURLFetcher: photoURLFetcher
        )
    }
    
    func makeListViewModel() -> ListViewModel {
        ListViewModel(postsRepository: postsRepository)
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    var container: Container!
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        initializePython()
        if let config = makeTelegramClientConfig() {
            container = Container(telegramClientConfig: config)
            return true
        }
        assertionFailure("Unable to create TelegramClientConfig")
        return false
    }
}

// MARK: - Private
private extension AppDelegate {
    func initializePython() {
        let stdLibURL = Bundle.main.url(forResource: "python-stdlib", withExtension: nil)!
        let pipsURL = Bundle.main.url(forResource: "pips", withExtension: nil)!
        PythonRuntime.initialize(stdLibURL: stdLibURL, pipsURL: pipsURL)
    }
    
    func makeTelegramClientConfig() -> TelegramClientConfig? {
        guard let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
              let scriptURL = Bundle.main.url(forResource: "swift-telegram-messages", withExtension: "py")
        else {
            return nil
        }
        
        return TelegramClientConfig(
            scriptURL: scriptURL,
            sessionPath: documentDirectoryURL.appendingPathComponent("session").path,
            apiId: 15845540,
            apiHash: "4cb8ba1d05d513ed32a86f62fcd0e499",
            phoneNumber: "+995555993502",
            codeRequestURL: "http://localhost:8080",
            channelId: -1001793067559
        )
    }
}
