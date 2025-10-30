//
//  ContentView.swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 29.10.25.
//

import SwiftUI

struct ContentView: View {
    
    //@Enviroment(\.showError) private var showError
    
    @Environment(\.showError) private var showError
    
    var body: some View {
        VStack {
            Button {
                showError(SampleError.operationFailed, "Show error")
            } label: {
                Text("Show Error")
            }
            
            NavigationLink("Details Screen") {
                DetailScreen()
            }
            
        }
        .padding()
    }
}

// ContentViewContainer is only created so our Previews can work
struct ContentViewContainer: View {
    
    @State private var errorWrapper: ErrorWrapper?
    
    var body: some View {
        NavigationStack {
            ContentView()
        }
        .environment(\.showError, ShowErrorAction(action: showError))
        .sheet(item: $errorWrapper) { errorWrapper in
            ErrorView(errorWrapper: errorWrapper)
        }
    }
    
    private func showError( error: Error, guidence: String) {
        errorWrapper = ErrorWrapper(error: error, guidance: guidence)
    }
}

#Preview {
    
    ContentViewContainer()
    
}
