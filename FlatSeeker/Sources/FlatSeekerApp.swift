//
//  FlatSeekerApp.swift
//  FlatSeeker
//
//  Created by Aleksei Muraveinik on 13.05.23.
//

import SwiftUI

@main
struct FlatSeekerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ListView(viewModel: .init(client: appDelegate.client))
        }
    }
}
