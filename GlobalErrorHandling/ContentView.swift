//
//  ContentView.swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 29.10.25.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(\.showError) private var showError
    @State private var showingSheet = false
    @State private var showingPopover = false
    
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
        .navigationTitle("ContentView")
        .toolbar {
            // Multiple toolbar items - modern approach
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showingPopover = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .popover(isPresented: $showingPopover) {
                    VStack(spacing: 16) {
                        Text("App Information")
                            .font(.headline)
                        Text("This demonstrates global error handling")
                            .multilineTextAlignment(.center)
                        Button("Dismiss") {
                            showingPopover = false
                        }
                    }
                    .padding()
                    .presentationCompactAdaptation(.sheet)
                }
                
                Button {
                    showingSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
            
            // Leading toolbar item
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showError(SampleError.operationFailed, "Toolbar Error Demo")
                } label: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }
            
            // Principal (center) toolbar item - great for important actions
            ToolbarItem(placement: .principal) {
                Button {
                    showError(SampleError.operationFailed, "Center action triggered")
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .font(.headline)
                    .foregroundStyle(.blue)
                }
            }
        }
        .sheet(isPresented: $showingSheet) {
            NavigationStack {
                VStack(spacing: 20) {
                    Text("Sheet Content")
                        .font(.largeTitle)
                    
                    Button {
                        showError(SampleError.operationFailed, "Sheet Error Demo")
                    } label: {
                        Text("Trigger Error from Sheet")
                    }
                    
                    Spacer()
                }
                .navigationTitle("Sheet View")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            showingSheet = false
                        }
                    }
                }
                .padding()
            }
            .presentationDetents([.medium, .large])
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
        .overlay(alignment: .bottom) {
            errorWrapper != nil ? ErrorView(errorWrapper: $errorWrapper) : nil
        }        /*
         .sheet(item: $errorWrapper) { errorWrapper in
             ErrorView(errorWrapper: errorWrapper)
         }
         */
        
        
    }
    
    private func showError( error: Error, guidence: String) {
        errorWrapper = ErrorWrapper(error: error, guidance: guidence)
    }
}

#Preview {
    
    ContentViewContainer()
    
}