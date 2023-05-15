import Foundation

func measure(_ call: () -> Void) {
    let start = CFAbsoluteTimeGetCurrent()
    call()
    let diff = CFAbsoluteTimeGetCurrent() - start
    print("Took \(diff) seconds")
}
