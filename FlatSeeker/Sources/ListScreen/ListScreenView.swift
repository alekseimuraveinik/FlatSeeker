import SwiftUI

struct ListScreenView: View {
    @StateObject var viewModel = ListScreenViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            TextField(text: $viewModel.code) {
                Text("Enter code")
            }
            
            Button("Submit", action: viewModel.signIn)
            
            Text(viewModel.text)
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(viewModel.photos, id: \.self) { url in
                        AsyncImage(url: url)
                    }
                }
            }
        }
        .onAppear(perform: viewModel.onAppear)
    }
}
