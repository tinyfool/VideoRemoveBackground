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

struct VideoEditorView: View {
    
    //for video processing
    @State private var backGroundMode = 1
    
    @State private var videoUrl:URL?
    @State private var videoAsset:AVAsset?
    @State private var videoFirstImage:NSImage?
    @State private var imageTransparent:NSImage?
    @State private var imagePreview:NSImage?

    @State private var videoFirstImageProcessing = false
    
    @State private var color = Color.green

    @State private var colorImage:NSImage?
    
    @State private var backgroundImage:NSImage?
    
    private var model = VideoMatting()
    
    var body: some View {
        VStack {
            videoPreview
            HStack {
                optionsPanel
                    .disabled(self.videoUrl == nil ||
                        self.videoFirstImageProcessing)
                buttonsPanel
            }
            Spacer()
        }
    }
    
    var videoPreview : some View {
        
        HStack {
            if videoAsset != nil {
                VideoPlayer(player: AVPlayer(url:  self.videoUrl!))
                    .frame(width: 384,height: 216)
            } else {
                
                ImageVideoRect()
            }
            if self.imagePreview != nil {
                
                Image(nsImage: self.imagePreview!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 384, height: 216, alignment: Alignment.center)
            }else {
                ZStack {
                    if self.videoFirstImageProcessing {
                        VStack {
                            Text("loading preview...")
                            ProgressView()
                        }
                    }
                    ImageVideoRect()
                }
            }
        }.padding()
    }
    
    var optionsPanel : some View {
        
        GroupBox(label: Text("Background modes")) {
            HStack {
                Picker(selection: $backGroundMode, label: Text("Mode")) {
                    Text("Transparent").tag(1)
                    Text("Color").tag(2)
                    Text("Image").tag(3)
                }
                .pickerStyle(RadioGroupPickerStyle())
                .padding()
                .onChange(of: backGroundMode) { mode in
                    if(mode != 3 || self.backgroundImage != nil) {
                        rebuildPreviewImage()
                    }
                }
                VStack {
                    if(backGroundMode == 2) {
                        ColorPicker("Select Color", selection: $color)
                            .onChange(of: color) { color in
                                self.colorImage = nil
                                rebuildPreviewImage()
                            }
                    }
                    if(backGroundMode == 3) {
                        Button {
                            SelectBackgroundImage()
                        } label: {
                            Text("Select Image")
                        }
                    }
                }
                .padding()
                .frame(width:200)
            }
        }
    }
    
    var buttonsPanel : some View {
        
        VStack (alignment:.leading) {
            Button {
                
                openVideo()
            } label: {
                Text("Select video...")
            }
            .padding(.top)
            .padding(.bottom)
            Button {
                
                
            } label: {
                Text("Save as...")
            }
            Spacer()
        }
    }

    fileprivate func openVideo() {
        
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.movie]
        
        if panel.runModal() == .OK {
            guard let videoFile = panel.url else {return}
            self.videoUrl = videoFile
            self.videoAsset = AVAsset(url: self.videoUrl!)
            if self.videoAsset != nil {
                getFirstImage()
                self.videoFirstImageProcessing = true
                DispatchQueue.global(qos: .background).async {
                    let newImage =
                    self.model.imageRemoveBackGround(srcImage: self.videoFirstImage!)
                    self.imageTransparent = newImage
                    rebuildPreviewImage()
                    DispatchQueue.main.async {
                        self.videoFirstImageProcessing = false
                    }
                }
            }
        }
    }
    
    fileprivate func getFirstImage() {
        
        let imageGenerator = AVAssetImageGenerator(asset: self.videoAsset!)
        imageGenerator.appliesPreferredTrackTransform = true
        guard let cgImage = try? imageGenerator.copyCGImage(at: CMTime(value: 1, timescale: 30), actualTime: nil) else {return}
        self.videoFirstImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
    
    fileprivate func rebuildPreviewImage() {
    
        var result:NSImage?
        
        if self.backGroundMode == 1 {
            result =  self.imageTransparent
        } else if self.backGroundMode == 2 {
            if self.colorImage == nil {
                self.colorImage = NSImage.imageWithColor(color: NSColor(color), size:self.imageTransparent!.size)
            }
            result = self.imageTransparent!.putOnImage(backgroundImage: self.colorImage!)
        } else if self.backGroundMode == 3 {
            result = self.imageTransparent!.putOnImage(backgroundImage: self.backgroundImage!)
        }
        else {
            result =  self.imageTransparent
        }
        
        DispatchQueue.main.async {
            self.imagePreview = result
        }
    }
    
    fileprivate func SelectBackgroundImage() {
        
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.image]
        if panel.runModal() == .OK {
            guard let imageFile = panel.url else {return}
            self.backgroundImage = NSImage(contentsOf:imageFile)
            if self.backgroundImage != nil {
                rebuildPreviewImage()
            }
        }
    }

}


struct VideoEditorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VideoEditorView()
        }
    }
}
