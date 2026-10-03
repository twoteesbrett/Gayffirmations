//
//  GayffirmationsApp.swift
//  Gayffirmations
//
//  Created by Brett Fisher on 28/09/2026.
//

import SwiftUI

@main
struct GayffirmationsApp: App {
    @State private var dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            ContentView(
                affirmationStore: dependencies.affirmationStore,
                scheduleStore: dependencies.scheduleStore,
                themeStore: dependencies.themeStore,
                notificationCoordinator: dependencies.notificationCoordinator,
                resetCoordinator: dependencies.resetCoordinator
            )
        }
    }
}
