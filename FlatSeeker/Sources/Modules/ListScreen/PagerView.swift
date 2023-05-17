import SwiftUI

struct PagerView: View {
    @ObservedObject var viewModel: PagerViewModel
    
    var body: some View {
        if viewModel.uiImages.isEmpty {
            ProgressView()
        } else {
            TabView {
                ForEach(viewModel.uiImages, id: \.self) { uiImage in
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                        .overlay {
                            if viewModel.uiImages.count == 1 {
                                ProgressView()
                            }
                        }
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .transition(.opacity)
        }
    }
}
