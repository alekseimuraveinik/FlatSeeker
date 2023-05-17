import Combine
import Foundation
import PythonRuntime
import UIKit

class DetailsViewModel: ViewModel {
    let text: String
    let district: String?
    let price: String?
    let imagesViewModel: ListItemImagesViewModel
    
    init(client: TelegramClient, group: MessageGroup, imagesViewModel: ListItemImagesViewModel) {
        text = group.textMessage
        district = group.district
        price = group.price
        self.imagesViewModel = imagesViewModel
    }
}
