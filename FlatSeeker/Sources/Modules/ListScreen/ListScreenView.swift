import SwiftUI

struct ListScreenView: View {
    @StateObject var viewModel: ListScreenViewModel
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 20) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.photos, id: \.self) { url in
                            Image(uiImage: url)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(
                                    width: UIScreen.main.bounds.width - 60,
                                    height: UIScreen.main.bounds.height / 2
                                )
                                .clipped()
                                .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                
                ProgressView()
                    .opacity(viewModel.isLoading ? 1 : 0)
                
                Text(viewModel.text)
                    .padding(.top, viewModel.isLoading ? 0 : -20)
                
                Spacer()
            }
        }
        .padding(.bottom, 20)
        .onAppear(perform: viewModel.onAppear)
    }
}
