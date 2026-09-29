//
//  SelfsaidApp.swift
//  Selfsaid
//
//  Created by Brett Fisher on 28/09/2026.
//

import SwiftUI

@main
struct SelfsaidApp: App {
    @State private var affirmationStore = AffirmationStore(
        repository: UserDefaultsRepository(),
        defaultAffirmations: Affirmation.samples
    )

    var body: some Scene {
        WindowGroup {
            ContentView(store: affirmationStore)
        }
    }
}
