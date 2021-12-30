//
//  ModelPoolRemoveBackgroundCompositor.swift
//  FreeGreenScreen
//
//  Created by HaoPeiqiang on 2021/12/27.
//

import Cocoa
import CoreML

class ModelPoolRemoveBackgroundCompositor: RemoveBackgroundCompositor {

    var model1080Pool = [rvm_mobilenetv3_1920x1080_s0_25_fp16]()
    var model720Pool = [rvm_mobilenetv3_1280x720_s0_375_fp16]()
    
    override init(){
        print("ModelPoolRemoveBackgroundCompositor init")
        let poolSize = 10
        model1080Pool = [rvm_mobilenetv3_1920x1080_s0_25_fp16]()
        let config = MLModelConfiguration()
        config.computeUnits = defaultComputeUnits
        for _ in 1...poolSize {
            let model = try? rvm_mobilenetv3_1920x1080_s0_25_fp16(configuration:config)
            model1080Pool.append(model!)
        }
        for _ in 1...poolSize {
            let model = try? rvm_mobilenetv3_1280x720_s0_375_fp16(configuration:config)
            model720Pool.append(model!)
        }
        super.init()
    }

    
}
