import SwiftUI

struct PageView: View {
    @Binding var images: [UIImage]
    
    var body: some View {
        TabView {
            ForEach(images, id: \.self) { image in
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            }
        }
        .tabViewStyle(PageTabViewStyle())
    }
}
