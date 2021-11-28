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
    @State private var videoBackgroundRemovedPreview:NSImage?
    
    @State private var videoFirstImageProcessing = false
    
    @State private var color = Color.green

    private var model = VideoMatting()
    
    var body: some View {
        VStack {
            videoView
            videoViewButtonPanel
            Spacer()
        }
    }
    
    var videoView : some View {
        
        HStack {
            if videoAsset != nil {
                VideoPlayer(player: AVPlayer(url:  self.videoUrl!))
                    .frame(width: 384,height: 216)
            } else {
                
                ImageVideoRect
            }
            if self.videoFirstImage != nil {
                
                ZStack {
                    if self.videoBackgroundRemovedPreview != nil {
                        Image(nsImage: self.videoBackgroundRemovedPreview!)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 384, height: 216, alignment: Alignment.center)
                    }
                    if self.videoFirstImageProcessing {
                        VStack {
                            Text("loading preview...")
                            ProgressView()
                        }
                    }
                }
            }else {
                ImageVideoRect
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
                }
                .frame(width:350)
            }
            
            VStack (alignment:.leading) {
                Button {
                    
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.allowedContentTypes = [.movie]
                    
                    if panel.runModal() == .OK {
                        guard let videoFile = panel.url else {return}
                        self.videoUrl = videoFile
                        self.videoAsset = AVAsset(url: self.videoUrl!)
                        if self.videoAsset != nil {
                            let imageGenerator = AVAssetImageGenerator(asset: self.videoAsset!)
                            imageGenerator.appliesPreferredTrackTransform = true
                            guard let cgImage = try? imageGenerator.copyCGImage(at: CMTime(value: 1, timescale: 30), actualTime: nil) else {return}
                            self.videoFirstImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                            self.videoFirstImageProcessing = true
                            DispatchQueue.global(qos: .background).async {
                                let newImage =
                                self.model.imageRemoveBackGround(srcImage: self.videoFirstImage!)
                                DispatchQueue.main.async {
                                    self.videoBackgroundRemovedPreview = newImage
                                    self.videoFirstImageProcessing = false
                                }
                            }
                        }
                    }
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
        .padding()
    }
    
    var ImageVideoRect : some View {
        
        Rectangle()
        .frame(width: 384, height: 216, alignment: Alignment.center)
        .foregroundColor(.clear)
        .border(.black, width: 1)
    }
    
}


struct VideoEditorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}
