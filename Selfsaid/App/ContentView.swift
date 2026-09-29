//
//  ContentView.swift
//  Selfsaid
//
//  Created by Brett Fisher on 28/09/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var store: AffirmationStore

    init(store: AffirmationStore) {
        _store = State(initialValue: store)
    }

    var body: some View {
        TabView {
            TodayView(store: store)
                .tabItem {
                    Label("Today", systemImage: "sun.max")
                }

            LibraryView(store: store)
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }

            ScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: "clock")
                }
        }
    }
}

#Preview {
    ContentView(
        store: AffirmationStore(affirmations: Affirmation.samples)
    )
}
