//
//  ContentView.swift
//  Shared
//
//  Created by Alexander Ivkin on 6/18/22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Button(action: {
            compose()
        }) {
            Text("Start")
        }.padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
