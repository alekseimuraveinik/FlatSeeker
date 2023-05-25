import Foundation
import PythonRuntime
import UIKit

class Container {
    private let telegramClient: TelegramClient
    private let photoURLFetcher: PhotoURLFetcher
    private let postsRepository: PostsRepository
    
    init(
        proof: PythonRuntime.Proof,
        telegramClientConfig: TelegramClientConfig,
        photoURLFetcherConfig: PhotoURLFetcherConfig
    ) {
        self.telegramClient = TelegramClient(proof: proof, config: telegramClientConfig)
        self.photoURLFetcher = PhotoURLFetcher(config: photoURLFetcherConfig)
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
        guard let proof = initializePython() else {
            assertionFailure("Unable to initialize Python")
            return false
        }
        
        guard let telegramClientConfig = makeTelegramClientConfig() else {
            assertionFailure("Unable to create TelegramClientConfig")
            return false
        }
        
        container = Container(
            proof: proof,
            telegramClientConfig: telegramClientConfig,
            photoURLFetcherConfig: makePhotoURLFetcherConfig()
        )
        return true
    }
}

// MARK: - Private
private extension AppDelegate {
    func initializePython() -> PythonRuntime.Proof? {
        guard let stdLibURL = Bundle.main.url(forResource: "python-stdlib", withExtension: nil),
           let pipsURL = Bundle.main.url(forResource: "pips", withExtension: nil)
        else {
            return nil
        }
        
        return PythonRuntime.initialize(stdLibURL: stdLibURL, pipsURL: pipsURL)
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
    
    func makePhotoURLFetcherConfig() -> PhotoURLFetcherConfig {
        PhotoURLFetcherConfig(
            makeWebPageURL: { URL(string: "https://t.me/tbilisi_arendaa/\($0)?embed=1&mode=tme") },
            targetURLRegex: /background-image:url\('(.*?\.jpg)'\)/,
            targetAuthorNameRegex: /<span dir="auto">(.*?)<\/span>/,
            targetAuthorImageURLRegex: /<img src="(.*?\.jpg)"><\/i>/
        )
    }
}
