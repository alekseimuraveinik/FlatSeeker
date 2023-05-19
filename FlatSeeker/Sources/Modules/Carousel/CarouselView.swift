import Combine
import SwiftUI

class CarouselViewModel: ObservableObject {
    let thumbnail: UIImage?
    @Published var images: [(Int, URL)]
    
    init(thumbnail: UIImage?, images: [URL]) {
        self.thumbnail = thumbnail
        self.images = Array(images.enumerated())
    }
}

struct CarouselView: View {
    @ObservedObject var viewModel: CarouselViewModel
    
    var body: some View {
        TabView {
            ForEach(viewModel.images, id: \.0) { index, url in
                GeometryReader { geometry in
                    AsyncImage(url: url) { image in
                        resizedImage(image, geometry: geometry)
                    } placeholder: {
                        if let thumbnail = viewModel.thumbnail, index == .zero {
                            resizedImage(Image(uiImage: thumbnail), geometry: geometry)
                        } else {
                            ProgressView()
                        }
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
