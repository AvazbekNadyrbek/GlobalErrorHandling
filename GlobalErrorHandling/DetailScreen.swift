//
//  DetailScreen.swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 30.10.25.
//

import SwiftUI

struct DetailScreen: View {
    
    @Environment(\.showError) private var showError
    var body: some View {
        Button("Throw Error from DetailScreen") {
            showError(SampleError.operationFailed, "Details Screen Error")
        }
    }
}

#Preview {
    DetailScreen()
}
