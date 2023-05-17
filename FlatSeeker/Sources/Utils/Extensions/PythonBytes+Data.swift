import Foundation
import PythonKit

extension PythonBytes {
    var data: Data {
        withUnsafeBytes { pointer in
            Data(pointer)
        }
    }
}

extension Array where Element == PythonObject {
    var data: [Data] {
        compactMap(PythonBytes.init)
            .map(\.data)
    }
}

extension PythonObject {
    var data: [Data] {
        Array(self).data
    }
    
    var bytes: PythonBytes? {
        PythonBytes(self)
    }
}
