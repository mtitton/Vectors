//
//  VectorsApp.swift
//  Vectors
//
//  Created by Marcus Titton on 13/10/26.
//

import SwiftUI

@main
struct VectorsApp: App {
    var body: some Scene {
        WindowGroup {
            RootGameView()
                .preferredColorScheme(.dark)
                .statusBarHidden()
                .persistentSystemOverlays(.hidden)
        }
    }
}
