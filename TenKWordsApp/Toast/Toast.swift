import SwiftUI

struct Toast: View {
    let message: String
    let isError: Bool

    var body: some View {
        Text(message)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(isError ? Color.red : Color.green)
            .cornerRadius(8)
    }
}
