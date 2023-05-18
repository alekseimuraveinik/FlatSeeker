import Foundation
import PythonKit

class PythonInteractor<StoredObjectKey: Hashable> {
    typealias GetStoredValue = (StoredObjectKey) -> PythonObject
    
    private let serialQueue = DispatchQueue(label: "pythonInteractorQueue", qos: .background)
    private var storage = [StoredObjectKey: PythonObject]()
    
    init(
        scripts: [URL],
        initializeStorage: @escaping (inout [StoredObjectKey: PythonObject], PythonInterface) -> Void
    ) {
        let scriptPaths = scripts.map { scriptURL in
            scriptURL.deletingLastPathComponent().path
        }
        serialQueue.async {
            let sys = Python.import("sys")
            for scriptPath in scriptPaths {
                sys.path.append(scriptPath)
            }
        }
        serialQueue.async {
            initializeStorage(&self.storage, Python)
        }
    }
    
    convenience init(
        script: URL,
        initializeStorage: @escaping (inout [StoredObjectKey: PythonObject], PythonInterface) -> Void
    ) {
        self.init(scripts: [script], initializeStorage: initializeStorage)
    }
    
    func execute<T>(
        _ action: @escaping (PythonInterface, GetStoredValue, (@escaping () -> Void) -> Void) -> T
    ) async -> T {
        await withUnsafeContinuation { continuation in
            serialQueue.async { [unowned self] in
                let result = action(
                    Python,
                    { self.storage[$0]! },
                    { call in
                        self.serialQueue.async {
                            call()
                        }
                    }
                )
                continuation.resume(with: .success(result))
            }
        }
    }
    
    func isolate<T>(
        _ object: PythonObject,
        _ action: @escaping (PythonObject, GetStoredValue) -> T
    ) async -> T {
        await withUnsafeContinuation { continuation in
            serialQueue.async { [unowned self] in
                let result = action(object, { self.storage[$0]! })
                continuation.resume(with: .success(result))
            }
        }
    }
}
