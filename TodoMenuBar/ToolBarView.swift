//
//  ToolBarView.swift
//  TodoMenuBar
//
//  Created by Marc J. Greenberg on 11/24/24.
//  Copyright © 2024 Codemarc Consulting, LLC. All rights reserved.
//
import SwiftUI

struct ToolBarView: View {
    let imageName: String
    let url: String
    let tooltip: String
    
    var body: some View {
        Button(action: { NSWorkspace.shared.open(URL(string: url)!) }) {
            Image(imageName)
           .resizable()
           .scaledToFit()
           .frame(width: 18, height: 18)
           .help(tooltip)
           .onHover { hovering in
               if hovering {
                   NSCursor.pointingHand.set()
               } else {
                   NSCursor.arrow.set()
               }
           }
       }
       .buttonStyle(.plain)
    }
    
}
