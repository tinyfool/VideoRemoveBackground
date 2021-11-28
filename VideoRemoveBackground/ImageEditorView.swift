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

struct ImageEditorView: View {
    
    @State private var image:NSImage?
    @State private var imageBackgroundRemoved:NSImage?
    @State private var imageProcessing = false

    private var model = VideoMatting()
    
    var body: some View {
        VStack(alignment:.center) {
            imageView
            imageViewButtons
            Spacer()
        }
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
                    imageToSave.saveTofile(file: file)
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

struct ImageEditorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}
