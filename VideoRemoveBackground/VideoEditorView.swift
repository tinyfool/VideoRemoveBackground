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
    @State private var firstImage:NSImage?
    @State private var imageTransparent:NSImage?
    @State private var firstImageProcessing = false
    
    @State private var color = Color.green
    @State private var colorImage:NSImage?
    
    @State private var processing = false
    @State private var progress:Float = 0.0
    
    @State var startTime:TimeInterval?
    
    var progressPercentage: String {
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value:self.progress )) ?? "0%"
    }

    var estimatedTime:String {
        
        if self.startTime == nil {
            return ""
        }
        let diff = Double(Date().timeIntervalSince1970 - self.startTime!)
        if diff < 5 {
            return ""
        }
        if self.progress == 0 {
            return ""
        }
        let et = Int((diff / Double(self.progress))*( 1 - Double(self.progress)))
        var seconds = et % 60
        var minutes = (et / 60) % 60
        var hours = (et / 3600)
        var day = (et/3600/24)
        if day > 0 {
            return "Estimated Time:\(day)D\(hours)H\(minutes)M\(seconds)S"

        }else if hours > 0 {
            return "Estimated Time:\(hours)H\(minutes)M\(seconds)S"

        }else if (minutes > 0) {
            return "Estimated Time:\(minutes)M\(seconds)S"
        }else {
            return "Estimated Time:\(seconds)S"
        }
    }
    
    private var model = VideoMatting()
    
    var body: some View {
        VStack {
            videoPreview.disabled(self.processing)
            HStack {
                optionsPanel
                    .disabled(self.videoUrl == nil ||
                              self.firstImageProcessing || self.processing)
                buttonsPanel.disabled(self.processing)
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
                    if self.firstImageProcessing {
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
                saveToFile()
            } label: {
                Text("Save as...")
            }
            .padding(.bottom)
            if self.processing {
                Text(self.progressPercentage)
                Text(self.estimatedTime)
                ProgressView(value: self.progress)
                    .frame(width:200)
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
                self.firstImageProcessing = true
                DispatchQueue.global(qos: .background).async {
                    let newImage =
                    self.model.imageRemoveBackGround(srcImage: self.firstImage!)
                    self.imageTransparent = newImage
                    self.colorImage = NSImage.imageWithColor(color: NSColor(color), size:self.imageTransparent!.size)
                    DispatchQueue.main.async {
                        self.firstImageProcessing = false
                    }
                }
            }
        }
    }
    
    fileprivate func getFirstImage() {
        
        let imageGenerator = AVAssetImageGenerator(asset: self.videoAsset!)
        imageGenerator.appliesPreferredTrackTransform = true
        guard let cgImage = try? imageGenerator.copyCGImage(at: CMTime(value: 1, timescale: 30), actualTime: nil) else {return}
        self.firstImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
    
    fileprivate func saveToFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.mpeg4Movie]
        if panel.runModal() == .OK {
            guard let destUrl = panel.url else { return }
            var color:Color?
            if self.backGroundMode == 2 {
                color = self.color
            }
            self.processing = true
            self.startTime = Date().timeIntervalSince1970
            DispatchQueue.global(qos: .background).async {

                model.videoRemoveBackground(srcURL: self.videoUrl!, destURL: destUrl, color: color, onProgressUpdate: {progress in
                    DispatchQueue.main.async {
                        self.progress = progress
                    }
                }) {
                    DispatchQueue.main.async {
                        self.processing = false
                        self.startTime = nil
                    }
                }
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
