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
    @State private var imageProcessing = false
    
    private var model = VideoMatting()
    
    var body: some View {
        TabView() {
            VStack(alignment:.center) {
                videoView
                videoViewButtonPanel
                Spacer()
            }
            .tabItem { Text("Video") }.tag(1)
            VStack {
                imageView
                imageViewButtons
                Spacer()
            }.tabItem { Text("Image") }.tag(2)
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
        }.padding()
    }
    
    var videoViewButtonPanel : some View {
        HStack(alignment: .top){
            GroupBox(label: Text("Options")) {
                HStack {
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
                    Spacer()
                }
                .frame(width:350)
            }
            
            VStack (alignment:.leading) {
                Button {
                    
                    let model = VideoMatting()
                    model.videoRemoveBackground()
                    
                } label: {
                    Text("Select video...")
                }
                .padding(.bottom)
                Button {
                    
                    let model = VideoMatting()
                    model.videoRemoveBackground()
                    
                } label: {
                    Text("Save as...")
                }
            }
        }
        .padding()
    }
    
    var imageView : some View {
        HStack {
            if image != nil {
                Image(nsImage: image!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 384, height: 216, alignment: Alignment.center)
            } else {
                ImageVideoRect
            }
            if((imageBackgroundRemoved) != nil) {
                Image(nsImage: imageBackgroundRemoved!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 384, height: 216, alignment: Alignment.center)
            }else {
                ZStack {

                    if self.imageProcessing {
                        VStack {
                            Text("processing...")
                            ProgressView()
                        }
                    }
                    ImageVideoRect
                }
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
                        self.imageBackgroundRemoved = nil
                        self.imageProcessing = true
                        DispatchQueue.global(qos: .background).async {
                            let newImage =
                            self.model.imageRemoveBackGround(srcImage: self.image!)
                            DispatchQueue.main.async {
                                self.imageBackgroundRemoved = newImage
                                self.imageProcessing = false
                            }
                        }
                    }
                }
            } label: {
                Text("Select Image...")
                    .padding()
            }
            .disabled(self.imageProcessing)
            .padding()

            Button {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                let copiedObjects = NSArray(object: self.imageBackgroundRemoved!)
                pasteboard.writeObjects(copiedObjects as! [NSPasteboardWriting])
            } label: {
                Text("Copy to clipboard")
            }
            .disabled(self.imageBackgroundRemoved == nil)
            .padding()

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
            .disabled(self.imageBackgroundRemoved == nil)
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
