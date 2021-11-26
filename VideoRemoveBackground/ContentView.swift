//
//  ContentView.swift
//  VideoRemoveBackground
//
//  Created by HaoPeiqiang on 2021/11/24.
//

import SwiftUI

struct ContentView: View {
    @State private var image:NSImage?
    @State private var imageBackgroundRemoved:NSImage?
    @State private var backGroundMode = 1
    @State private var color = Color.green
    
    var model = VideoMatting()
    
    var body: some View {
        TabView() {
            VStack {
                imageView
                imageViewButtons
            }.tabItem { Text("Image") }.tag(2)
            VStack() {
                videoView
                videoViewButtonPanel
                Spacer()
            }
            .tabItem { Text("Video") }.tag(1)
            .padding()
        }
        .padding()
    }
    
    var videoView : some View {
        
        HStack {
            Image("news")
                .resizable()
                .frame(width: 384, height: 216, alignment: Alignment.center)
                .scaledToFit()
            if((image) != nil) {
                Image(nsImage: image!).resizable()
                    .frame(width: 384, height: 216, alignment: Alignment.center)
                    .scaledToFit()
            }else {
                Rectangle()
                    .frame(width: 384, height: 216, alignment: Alignment.center)
            }
        }
    }
    
    var videoViewButtonPanel : some View {
        
        HStack(alignment: .top){
            Picker(selection: $backGroundMode, label: Text("Mode")) {
                Text("Transparent").tag(1)
                Text("Color").tag(2)
                Text("Image").tag(3)
            }
            .pickerStyle(RadioGroupPickerStyle())
            .padding()
            .onChange(of: backGroundMode) { mode in
                
            }
            VStack {
                if(backGroundMode == 1) {
                    Text("")
                }
                if(backGroundMode == 2) {
                    ColorPicker("Select Color", selection: $color)
                }
                if(backGroundMode == 3) {
                    Text("Select Image")
                }
            }
            .padding()
            Button {
                
                let model = VideoMatting()
                model.videoRemoveBackground()
                
            } label: {
                Text("Video remove background")
            }
            Spacer()
        }
    }
    
    var imageView : some View {
        HStack {
            if image != nil {
                Image(nsImage: image!)
                    .resizable()
                    .frame(width: 384, height: 216, alignment: Alignment.center)
                    .scaledToFit()
            } else {
                ImageVideoRect
            }
            if((imageBackgroundRemoved) != nil) {
                Image(nsImage: imageBackgroundRemoved!).resizable()
                    .frame(width: 384, height: 216, alignment: Alignment.center)
                    .scaledToFit()
            }else {
                ImageVideoRect
            }
        }
        .padding()
    }
    
    var ImageVideoRect : some View {
        
        Rectangle()
        .frame(width: 384, height: 216, alignment: Alignment.center)
        .foregroundColor(.clear)
        .border(.black, width: 1)
    }
    
    var imageViewButtons : some View {
        
        HStack {
            Button  {
                let panel = NSOpenPanel()
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false
                panel.allowedContentTypes = [.image]
                if panel.runModal() == .OK {
                    guard let imageFile = panel.url else {return}
                    self.image = NSImage(contentsOf:imageFile)
                    if self.image != nil {
                        self.imageBackgroundRemoved =
                        self.model.imageRemoveBackGround(srcImage: self.image!)
                    }
                }
            } label: {
                Text("Open Image File...")
                    .padding()
            }.padding()

            Button {
                let panel = NSSavePanel()
                panel.allowedContentTypes = [.png]
                if panel.runModal() == .OK {
                    guard let file = panel.url else {return}
                    guard let imageToSave = self.imageBackgroundRemoved else {return}
                    saveTofile(imageToSave: imageToSave, file: file)
                }
            } label: {
                Text("Save as...")
                    .padding()
            }
            .padding()
        }
    }
}

func saveTofile(imageToSave:NSImage, file:URL) {
    guard let imageData = imageToSave.tiffRepresentation else {return}
    let imageRep = NSBitmapImageRep(data:imageData)
    guard let data = imageRep?.representation(using: .png, properties: [:]) else {return}
    try? data.write(to: file)
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}
