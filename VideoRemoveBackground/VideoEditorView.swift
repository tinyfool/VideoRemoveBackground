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
            if self.imageTransparent != nil {
                
                ZStack {
                    if self.backGroundMode == 2 {
                        
                        Image(nsImage: self.colorImage!)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 384, height: 216, alignment: Alignment.center)
                        
                    }
                    Image(nsImage: self.imageTransparent!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 384, height: 216, alignment: Alignment.center)
                }
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
                }
                .pickerStyle(RadioGroupPickerStyle())
                .padding()
                VStack {
                    if(backGroundMode == 2) {
                        ColorPicker("Select Color", selection: $color)
                            .onChange(of: color) { color in
                                self.colorImage = NSImage.imageWithColor(color: NSColor(color), size:self.imageTransparent!.size)
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
                    self.colorImage = NSImage.imageWithColor(color: NSColor(color), size:self.imageTransparent!.size)
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
        
}


struct VideoEditorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VideoEditorView()
        }
    }
}
