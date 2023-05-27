import Foundation

struct PostImage {
    let thumbnail: Data
    let imageURL: URL
}

struct PostDTO {
    let id: Int
    let date: Date
    let authorId: Int
    let authorName: String
    let authorImage: URL
    let text: String
    let price: Int?
    let district: String?
    let images: [PostImage]
    let deeplinkURL: URL
    let postURL: URL
}
