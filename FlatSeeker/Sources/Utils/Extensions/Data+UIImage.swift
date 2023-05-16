import UIKit

extension Array where Element == Data {
    var uiImages: [UIImage] {
        compactMap(UIImage.init)
    }
}
