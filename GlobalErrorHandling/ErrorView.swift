//
//  ErrorView.swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 30.10.25.
//

import SwiftUI

struct ErrorView: View {
    
    let errorWrapper: ErrorWrapper
    
    var body: some View {
        VStack {
            Text(errorWrapper.error.localizedDescription)
            Text(errorWrapper.guidance)
        }
    }
}

#Preview {
    ErrorView(errorWrapper: ErrorWrapper(error: SampleError.operationFailed, guidance: "Operation Failed please try again later"))
}
