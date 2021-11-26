//
//  VideoMatting.swift
//  VideoRemoveBackground
//
//  Created by HaoPeiqiang on 2021/11/24.
//

import Cocoa
import CoreML
import SwiftUI
import CoreImage
import AVFoundation
import AVKit



func pixelBuffer2Image(buffer:CVPixelBuffer) -> NSImage {
    
    let ciImage = CIImage.init(cvPixelBuffer: buffer)
    return ciImage2Image(ciImage: ciImage)
}

func ciImage2Image(ciImage:CIImage) -> NSImage {
    
    let rep = NSCIImageRep(ciImage: ciImage)
    let nsImage = NSImage(size: rep.size)
    nsImage.addRepresentation(rep)
    return nsImage
}

class VideoMatting: NSObject {

    func imageRemoveBackGround(srcImage:NSImage) -> NSImage? {
        
        let config = MLModelConfiguration()
        guard let model = try? rvm_mobilenetv3_1920x1080_s0_25_fp16(configuration:config) else {return nil}
        
        var imageRect = CGRect(x: 0,y: 0,width: srcImage.size.width,height: srcImage.size.height)
        guard let cgImage = srcImage.cgImage(forProposedRect: &imageRect, context: nil, hints: nil) else {return nil}

        guard let input = try? rvm_mobilenetv3_1920x1080_s0_25_fp16Input(srcWith:cgImage, r1i: MLMultiArray(), r2i: MLMultiArray(), r3i: MLMultiArray(), r4i: MLMultiArray()) else {return nil}
        
        guard let result = try? model.prediction(input: input) else {return nil}
        
        guard let transImage = makeTransparentImage(imageBuffer: result.fgr, maskBuffer: result.pha) else {return nil}
        if srcImage.size == transImage.size {
            
            return transImage
        }
        let resizedImage = transImage.copy(size: srcImage.size)
        return resizedImage
    }
        
    func makeTransparentImage(imageBuffer:CVPixelBuffer, maskBuffer:CVPixelBuffer) -> NSImage? {
        
        let fgrImage = CIImage.init(cvPixelBuffer: imageBuffer)
        let maskImage = CIImage.init(cvPixelBuffer: maskBuffer)
        guard let maskFilter = CIFilter(name: "CIMaskToAlpha") else {return nil}
        maskFilter.setValue(maskImage, forKey: kCIInputImageKey)
        let alphaMaskImage = maskFilter.outputImage
        guard let blendFilter = CIFilter(name: "CIBlendWithAlphaMask") else {return nil}
        blendFilter.setValue(fgrImage, forKey: kCIInputImageKey)
        blendFilter.setValue(alphaMaskImage, forKey: kCIInputMaskImageKey)
        guard let outImage = blendFilter.outputImage else {return nil}
        return ciImage2Image(ciImage: outImage)
    }
    
    //TODO: 完成视频处理能力
    func videoRemoveBackground() {
        
        guard let url = Bundle.main.url(forResource: "my30", withExtension: "mp4") else {
            fatalError("The required video asset wasn't found in the app bundle.")
        }
        
        let asset = AVAsset(url: url)
        
        let avComposition = AVMutableComposition()
        
        let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        
        guard let videoTrack = avComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {return}
        
        
        if  let sourceTrack = asset.tracks(withMediaType: .video).first {
            try? videoTrack.insertTimeRange(timeRange, of: sourceTrack, at: .zero)
        }
        
        var instructionLayers = [AVMutableVideoCompositionLayerInstruction]()
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        instructionLayers.append(layerInstruction)
        
        let compositionInstruction = AVMutableVideoCompositionInstruction()
        compositionInstruction.timeRange = timeRange
        compositionInstruction.layerInstructions = instructionLayers
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [compositionInstruction]
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.renderSize = videoTrack.naturalSize
        videoComposition.customVideoCompositorClass = RemoveBackgroundCompositor.self

        guard let exportSession = AVAssetExportSession(asset: avComposition,
                                                       presetName: AVAssetExportPreset1920x1080) else {
            fatalError("Unable to create AVAssetExportSession.")
        }
        exportSession.videoComposition = videoComposition
        exportSession.outputURL = URL(fileURLWithPath: "/tmp/temp.mp4")
        exportSession.exportAsynchronously {
            if [.completed].contains(exportSession.status) {
                print("exportSession completed")
            }
            if [.failed].contains(exportSession.status) {
                print("exportSession failed")
            }
            if [.cancelled].contains(exportSession.status) {
                print("exportSession cancelled")
            }

        }

    }
}

enum CustomCompositorError: Int, Error, LocalizedError {
    case ciFilterFailedToProduceOutputImage = -1_000_001
    case notSupportingMoreThanOneSources
    case CoreMLError
    var errorDescription: String? {
        switch self {
        case .ciFilterFailedToProduceOutputImage:
            return "CIFilter does not produce an output image."
        case .notSupportingMoreThanOneSources:
            return "This custom compositor does not support blending of more than one source."
        case .CoreMLError:
            return "CoreML Error"
        }
    }
}

class RemoveBackgroundCompositor:NSObject, AVVideoCompositing {
    
    var model:rvm_mobilenetv3_1920x1080_s0_25_fp16?
    private let coreImageContext = CIContext(options: [CIContextOption.cacheIntermediates: false])

    override init() {
        let config = MLModelConfiguration()
        guard let newModel = try? rvm_mobilenetv3_1920x1080_s0_25_fp16(configuration:config) else {return}
        self.model = newModel
    }

    var sourcePixelBufferAttributes: [String : Any]? = [String(kCVPixelBufferPixelFormatTypeKey): [kCVPixelFormatType_32BGRA
]]
    
    var requiredPixelBufferAttributesForRenderContext: [String : Any] =         [String(kCVPixelBufferPixelFormatTypeKey): [kCVPixelFormatType_32BGRA
]]

    
    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        return
    }
    
    func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
        
        guard let requiredTrackIDs = request.videoCompositionInstruction.requiredSourceTrackIDs, !requiredTrackIDs.isEmpty else {
            print("No valid track IDs found in composition instruction.")
            return
        }
        
        guard let outputPixelBuffer = request.renderContext.newPixelBuffer() else {
            print("No valid pixel buffer found. Returning.")
            request.finish(with: CustomCompositorError.ciFilterFailedToProduceOutputImage)
            return
        }

        let sourceCount = requiredTrackIDs.count

        if sourceCount > 1 {
            request.finish(with: CustomCompositorError.notSupportingMoreThanOneSources)
            return
        }

        if sourceCount == 1 {
            let sourceID = requiredTrackIDs[0]
            let sourceBuffer = request.sourceFrame(byTrackID: sourceID.value(of: Int32.self)!)!
            let input = rvm_mobilenetv3_1920x1080_s0_25_fp16Input(src: sourceBuffer, r1i:  MLMultiArray(), r2i: MLMultiArray(), r3i: MLMultiArray(), r4i: MLMultiArray())

            guard let result = try? self.model!.prediction(input: input) else {
                request.finish(with: CustomCompositorError.CoreMLError)
                return
            }
            let destImage = CIImage(cvPixelBuffer: result.pha)
            render(ciImage: destImage, destBuffer: outputPixelBuffer)
            request.finish(withComposedVideoFrame: result.pha)
        }
    }
    
    func render(ciImage:CIImage,destBuffer:CVPixelBuffer) {
        
        let renderDestination = CIRenderDestination(pixelBuffer: destBuffer)
        do {
            
            try coreImageContext.startTask(toRender: ciImage, to: renderDestination)
        } catch {
            print("Error starting request: \(error)")
        }

    }
}

