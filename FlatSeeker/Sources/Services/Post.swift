import Foundation

struct Post {
    let id: Int
    let textMessage: String
    let district: String?
    let price: String?
    let thumbnail: Data
    let images: [URL]
}
