import SwiftUI

struct ListScreenView: View {
    @StateObject var viewModel: ListScreenViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 20) {
                    PageView(images: $viewModel.photos)
                        .frame(
                            width: UIScreen.main.bounds.width,
                            height: UIScreen.main.bounds.height / 2
                        )
                        .padding(.top, 20)
                    
                    Text(viewModel.text)
                        .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            
            Button(action: viewModel.onNext) {
                Text("Следующая квартира")
                    .foregroundColor(Color.white)
                    .padding(20)
                    .frame(height: 48)
                    .background(
                        Color.blue
                            .cornerRadius(16)
                    )
            }
        }
        .padding(.bottom, 20)
        .overlay(
            ZStack {
                Color.black
                    .opacity(0.3)
                
                VStack(spacing: 20) {
                    ProgressView()
                    Text("Загрузка квартир")
                }
                .padding(20)
                .background(Color.white.cornerRadius(20).ignoresSafeArea())
            }
            .opacity(viewModel.isLoading ? 1 : 0)
        )
        .onAppear(perform: viewModel.onAppear)
    }
}
