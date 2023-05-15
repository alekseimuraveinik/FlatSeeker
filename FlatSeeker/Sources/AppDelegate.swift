import Foundation
import PythonRuntime
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    var client: Client!
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        initializePython()
        client = .init()
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
}
