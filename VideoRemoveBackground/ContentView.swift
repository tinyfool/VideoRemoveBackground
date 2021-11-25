//
//  ContentView.swift
//  VideoRemoveBackground
//
//  Created by HaoPeiqiang on 2021/11/24.
//

import SwiftUI

struct ContentView: View {
    @State var image:NSImage?
    var body: some View {
        VStack {
            Image("news")
                .resizable()
                .frame(minWidth: 100, idealWidth: 200, maxWidth: 300, minHeight: 100, idealHeight:150, maxHeight: 200, alignment: Alignment.center)
                .scaledToFit()
            if((image) != nil) {
                Image(nsImage: image!).resizable()
                    .frame(minWidth: 100, idealWidth: 200, maxWidth: 300, minHeight: 100, idealHeight:150, maxHeight: 200, alignment: Alignment.center)
                    .scaledToFit()

            }
            Button {
                guard let srcImage = NSImage(named: "news") else {return}
                let model = VideoMatting()
                image = model.imageRemoveBackGround(srcImage: srcImage)
            } label: {
                Text("remove background")
                    .padding()
            }

            Button {
                
                let model = VideoMatting()
                model.videoRemoveBackground()
                
            } label: {
                Text("Video remove background")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
