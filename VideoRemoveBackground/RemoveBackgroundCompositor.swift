//
//  RemoveBackgroundCompositor.swift
//  FreeGreenScreen
//
//  Created by HaoPeiqiang on 2021/12/26.
//

import Foundation
import Cocoa
import CoreML
import SwiftUI
import CoreImage
import AVFoundation
import AVKit

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
    
    override init(){
        super.init()
        print("RemoveBackgroundCompositor init")
    }
    
    private var model1080:rvm_mobilenetv3_1920x1080_s0_25_fp16 = {
    
        let config = MLModelConfiguration()
        config.computeUnits = defaultComputeUnits
        let _model1080 = try? rvm_mobilenetv3_1920x1080_s0_25_fp16(configuration:config)
        return _model1080!
    }()
    
    private var model720: rvm_mobilenetv3_1280x720_s0_375_fp16 = {
    
        let config = MLModelConfiguration()
        config.computeUnits = defaultComputeUnits
        let _model720 = try? rvm_mobilenetv3_1280x720_s0_375_fp16(configuration:config)
        return _model720!
    }()

    private let coreImageContext = CIContext(options: [CIContextOption.cacheIntermediates: false])

    var sourcePixelBufferAttributes: [String : Any]? = [String(kCVPixelBufferPixelFormatTypeKey): [kCVPixelFormatType_32BGRA
]]
    
    var requiredPixelBufferAttributesForRenderContext: [String : Any] =         [String(kCVPixelBufferPixelFormatTypeKey): [kCVPixelFormatType_32BGRA
]]

    
    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        return
    }
    
    func model1080Prediction(pixelBuffer:CVPixelBuffer) -> CIImage? {
        
        guard let input = try? rvm_mobilenetv3_1920x1080_s0_25_fp16Input(src:pixelBuffer, r1i: MLMultiArray(), r2i: MLMultiArray(), r3i: MLMultiArray(), r4i: MLMultiArray()) else {return nil}
        guard let result = try? self.model1080.prediction(input: input) else {return nil}
        guard let transImage = result.fgr.makeTransparentImage(maskBuffer: result.pha) else {return nil}
        return transImage
    }
    
    func model1080PredictionWithCGImage(pixelBuffer:CVPixelBuffer) -> CIImage? {
        
        guard let image = CGImage.create(pixelBuffer: pixelBuffer) else {return nil}
        guard let input = try? rvm_mobilenetv3_1920x1080_s0_25_fp16Input(srcWith:image, r1i: MLMultiArray(), r2i: MLMultiArray(), r3i: MLMultiArray(), r4i: MLMultiArray()) else {return nil}
        guard let result = try? self.model1080.prediction(input: input) else {return nil}
        guard let transImage = result.fgr.makeTransparentImage(maskBuffer: result.pha) else {return nil}
        return transImage
    }

    
    func model720Prediction(pixelBuffer:CVPixelBuffer)  -> CIImage? {
        
        guard let input = try? rvm_mobilenetv3_1280x720_s0_375_fp16Input(src:pixelBuffer, r1i: MLMultiArray(), r2i: MLMultiArray(), r3i: MLMultiArray(), r4i: MLMultiArray()) else {return nil}
        guard let result = try? self.model720.prediction(input: input) else {return nil}
        guard let transImage = result.fgr.makeTransparentImage(maskBuffer: result.pha) else {return nil}
        return transImage
    }
    
    func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
        
        print(Thread.current)
        guard let outputPixelBuffer = request.renderContext.newPixelBuffer() else {
            print("No valid pixel buffer found. Returning.")
            request.finish(with: CustomCompositorError.ciFilterFailedToProduceOutputImage)
            return
        }

        guard let requiredTrackIDs = request.videoCompositionInstruction.requiredSourceTrackIDs, !requiredTrackIDs.isEmpty else {
            print("No valid track IDs found in composition instruction.")
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

            var resultImage:CIImage?
            
            if CVPixelBufferGetHeight(sourceBuffer) == 720 {
                resultImage = model720Prediction(pixelBuffer: sourceBuffer)
            } else {
                if CVPixelBufferGetHeight(sourceBuffer)>1080 {
                    resultImage = model1080PredictionWithCGImage(pixelBuffer: sourceBuffer)
                }else {
                    resultImage = model1080Prediction(pixelBuffer: sourceBuffer)
                }
            }
            
            if resultImage == nil {
                request.finish(with: CustomCompositorError.CoreMLError)
                return
            }
            
            let renderDestination = CIRenderDestination(pixelBuffer: outputPixelBuffer)
            do {
                try coreImageContext.startTask(toRender: resultImage!, to: renderDestination)
            } catch {
                print("Error starting request: \(error)")
            }
            request.finish(withComposedVideoFrame: outputPixelBuffer)
        }
    }
}
