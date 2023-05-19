import Combine
import SwiftUI

struct CarouselImage: Identifiable {
    let id: Int
    let thumbnail: UIImage
    let imageURL: URL
}

class CarouselViewModel: ObservableObject {
    @Published var images: [CarouselImage]
    
    init(images: [PostImage]) {
        self.images = images.enumerated().map { index, image in
            CarouselImage(
                id: index,
                thumbnail: UIImage(data: image.thumbnail) ?? UIImage(),
                imageURL: image.imageURL
            )
        }
    }
}

struct CarouselView: View {
    @ObservedObject var viewModel: CarouselViewModel
    
    var body: some View {
        TabView {
            ForEach(viewModel.images) { image in
                GeometryReader { geometry in
                    AsyncImage(url: image.imageURL) { image in
                        resizedImage(image, geometry: geometry)
                    } placeholder: {
                        resizedImage(Image(uiImage: image.thumbnail), geometry: geometry)
                    }
                }
            }
        }
        .tabViewStyle(PageTabViewStyle())
    }
}

private func resizedImage(_ image: Image, geometry: GeometryProxy) -> some View {
    image
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: geometry.size.width, height: geometry.size.height)
        .clipped()
}
