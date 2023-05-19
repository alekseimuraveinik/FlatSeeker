import Foundation
import PythonKit

extension PythonBytes {
    var data: Data {
        withUnsafeBytes { pointer in
            Data(pointer)
        }
    }
}
