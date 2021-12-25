//
//  VideoRemoveBackgroundTests.swift
//  VideoRemoveBackgroundTests
//
//  Created by HaoPeiqiang on 2021/11/24.
//

import XCTest
@testable import FreeGreenScreen
import CoreML

class VideoRemoveBackgroundTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    
    func predicition(model:rvm_mobilenetv3_1920x1080_s0_25_fp16) {
        
        let image1 = NSImage(named: "test1")?.cgImage(forProposedRect: nil, context: nil, hints: nil)
        let input = try? rvm_mobilenetv3_1920x1080_s0_25_fp16Input(srcWith:image1!, r1i: MLMultiArray(), r2i: MLMultiArray(), r3i: MLMultiArray(), r4i: MLMultiArray())
        _ = try? model.prediction(input: input!)

    }
    
    func predicitionWithInt8(model:rvm_mobilenetv3_1920x1080_s0_25_int8) {
        
        let image1 = NSImage(named: "test1")?.cgImage(forProposedRect: nil, context: nil, hints: nil)
        let input = try? rvm_mobilenetv3_1920x1080_s0_25_int8Input(srcWith:image1!, r1i: MLMultiArray(), r2i: MLMultiArray(), r3i: MLMultiArray(), r4i: MLMultiArray())
        _ = try? model.prediction(input: input!)
    }

    
    func testDefaultSettingPerformance() throws {
        
        let config = MLModelConfiguration()
        let model = try rvm_mobilenetv3_1920x1080_s0_25_fp16(configuration: config)
        self.measure {
            predicition(model: model)
        }
    }
    
    func testAllPerformance() throws {
        
        let config = MLModelConfiguration()
        config.computeUnits = .all
        let model = try rvm_mobilenetv3_1920x1080_s0_25_fp16(configuration: config)
        self.measure {
            predicition(model:model)
        }
    }

    func testAllPerformanceWithANE() throws {
        
        let config = MLModelConfiguration()
        config.computeUnits = .all
        let model = try rvm_mobilenetv3_1920x1080_s0_25_fp16_ANE(configuration: config)
        self.measure {
            let image1 = NSImage(named: "test1")?.cgImage(forProposedRect: nil, context: nil, hints: nil)
            let input = try? rvm_mobilenetv3_1920x1080_s0_25_fp16_ANEInput(srcWith:image1!, r1i: MLMultiArray(), r2i: MLMultiArray(), r3i: MLMultiArray(), r4i: MLMultiArray())
            _ = try? model.prediction(input: input!)
        }
    }

    func testAllPerformanceInt8WithANE() throws {
        
        let config = MLModelConfiguration()
        config.computeUnits = .all
        let model = try rvm_mobilenetv3_1920x1080_s0_25_int8_ANE(configuration: config)
        self.measure {
            let image1 = NSImage(named: "test1")?.cgImage(forProposedRect: nil, context: nil, hints: nil)
            let input = try? rvm_mobilenetv3_1920x1080_s0_25_int8_ANEInput(srcWith:image1!, r1i: MLMultiArray(), r2i: MLMultiArray(), r3i: MLMultiArray(), r4i: MLMultiArray())
            _ = try? model.prediction(input: input!)
        }
    }

    func testCpuOnlyPerformance() throws {
        
        let config = MLModelConfiguration()
        config.computeUnits = .cpuOnly
        let model = try rvm_mobilenetv3_1920x1080_s0_25_fp16(configuration: config)
        self.measure {
            predicition(model:model)
        }
    }

    func testCpuAndGPUPerformance() throws {
        
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndGPU
        let model = try rvm_mobilenetv3_1920x1080_s0_25_fp16(configuration: config)
        self.measure {
            predicition(model:model)
            
        }
    }

    func testCpuAndGPUWithInt8Performance() throws {
        
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndGPU
        let model = try rvm_mobilenetv3_1920x1080_s0_25_int8(configuration: config)
        self.measure {
            predicitionWithInt8(model: model)
        }
    }

    func testOneThread() throws {
        
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndGPU
        let model = try rvm_mobilenetv3_1920x1080_s0_25_fp16(configuration: config)
        self.measure {
            
            predicition(model: model)
            predicition(model: model)
            predicition(model: model)
            predicition(model: model)
            predicition(model: model)
            predicition(model: model)
            predicition(model: model)
            predicition(model: model)
            predicition(model: model)
            predicition(model: model)
        }
    }

    func testMutilThread() throws {
        
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndGPU
        let model1 = try rvm_mobilenetv3_1920x1080_s0_25_fp16(configuration: config)
        let model2 = try rvm_mobilenetv3_1920x1080_s0_25_fp16(configuration: config)
        let model3 = try rvm_mobilenetv3_1920x1080_s0_25_fp16(configuration: config)
        let model4 = try rvm_mobilenetv3_1920x1080_s0_25_fp16(configuration: config)
        let model5 = try rvm_mobilenetv3_1920x1080_s0_25_fp16(configuration: config)
        let model6 = try rvm_mobilenetv3_1920x1080_s0_25_fp16(configuration: config)
        let model7 = try rvm_mobilenetv3_1920x1080_s0_25_fp16(configuration: config)
        let model8 = try rvm_mobilenetv3_1920x1080_s0_25_fp16(configuration: config)
        let model9 = try rvm_mobilenetv3_1920x1080_s0_25_fp16(configuration: config)
        let model10 = try rvm_mobilenetv3_1920x1080_s0_25_fp16(configuration: config)

        self.measure {

            DispatchQueue.concurrentPerform(iterations: 5) { i in
                self.predicition(model: model1)
                self.predicition(model: model2)
                self.predicition(model: model3)
                self.predicition(model: model4)
                self.predicition(model: model5)
                self.predicition(model: model6)
                self.predicition(model: model7)
                self.predicition(model: model8)
                self.predicition(model: model9)
                self.predicition(model: model10)
            }
        }
    }
}
