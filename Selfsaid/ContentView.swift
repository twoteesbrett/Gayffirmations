//
//  ContentView.swift
//  Selfsaid
//
//  Created by Brett Fisher on 28/09/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var store = AffirmationStore(
        affirmations: Affirmation.samples
    )

    var body: some View {
        TabView {
            Tab("Today", systemImage: "sun.max") {
                TodayView(store: store)
            }

            Tab("Library", systemImage: "books.vertical") {
                LibraryView(store: store)
            }
        }
    }
}

#Preview {
    ContentView()
}
