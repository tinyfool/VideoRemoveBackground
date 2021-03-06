//
//  ContentView.swift
//  VideoRemoveBackground
//
//  Created by HaoPeiqiang on 2021/11/24.
//

import SwiftUI
import AVFoundation
import AVKit
import CoreImage

struct ContentView: View {
    

    private var model = VideoMatting()
    
    var body: some View {
        TabView() {
            VideoEditorView()
                .tabItem { Text("Video") }.tag(1)
            ImageEditorView()
                .tabItem { Text("Image") }.tag(2)
        }
        .padding()
    }
    
}

struct ImageVideoRect : View {
    
    var body : some View {
    
        Rectangle()
        .frame(width: 384, height: 216, alignment: Alignment.center)
        .foregroundColor(.clear)
        .border(.black, width: 1)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}
