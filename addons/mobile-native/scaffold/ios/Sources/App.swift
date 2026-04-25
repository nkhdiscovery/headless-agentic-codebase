// {{PROJECT_NAME}}App.swift — entry point. Open ios/ in Xcode to add to project.

import SwiftUI

@main
struct AppMain: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("{{PROJECT_NAME}}")
                .font(.largeTitle)
                .fontWeight(.semibold)
            Text("Native iOS scaffold ready.")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
