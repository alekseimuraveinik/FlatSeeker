import Foundation
import PythonKit

public extension PythonBytes {
    var data: Data {
        withUnsafeBytes { pointer in
            Data(pointer)
        }
    }
}
