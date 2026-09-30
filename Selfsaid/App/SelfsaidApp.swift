//
//  SelfsaidApp.swift
//  Selfsaid
//
//  Created by Brett Fisher on 28/09/2026.
//

import SwiftUI

@main
struct SelfsaidApp: App {
    @State private var affirmationStore: AffirmationStore
    @State private var scheduleStore: ScheduleStore

    init() {
//  For testing startup failure of a corrupted store
//  Step 1. Uncomment these lines to cause the error
//        UserDefaults.standard.set(
//            Data("invalid JSON".utf8),
//            forKey: "Selfsaid.schedule"
//        )
        
//  Step 2. Uncomment these lines to remove the error
//        UserDefaults.standard.removeObject(
//            forKey: "Selfsaid.schedule"
//        )
        
        let repository = UserDefaultsRepository()
        _affirmationStore = State(
            initialValue: AffirmationStore(
                repository: repository,
                defaultAffirmations: Affirmation.samples
            )
        )
        _scheduleStore = State(
            initialValue: ScheduleStore(
                repository: repository,
                defaultSchedule: AffirmationSchedule()
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                affirmationStore: affirmationStore,
                scheduleStore: scheduleStore
            )
        }
    }
}
