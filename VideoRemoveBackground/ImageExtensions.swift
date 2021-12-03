//
//  NSImageExtensions.swift
//  VideoRemoveBackground
//
//  copy from https://gist.github.com/MaciejGad/11d8469b218817290ee77012edb46608
//

import Foundation
import SwiftUI
import VideoToolbox

extension NSImage {
    
    /// Returns the height of the current image.
    var height: CGFloat {
        return self.size.height
    }
    
    /// Returns the width of the current image.
    var width: CGFloat {
        return self.size.width
    }
    
    /// Returns a png representation of the current image.
    var PNGRepresentation: Data? {
        if let tiff = self.tiffRepresentation, let tiffData = NSBitmapImageRep(data: tiff) {
            return tiffData.representation(using: .png, properties: [:])
        }
        
        return nil
    }
    
    ///  Copies the current image and resizes it to the given size.
    ///
    ///  - parameter size: The size of the new image.
    ///
    ///  - returns: The resized copy of the given image.
    func copy(size: NSSize) -> NSImage? {
        // Create a new rect with given width and height
        let frame = NSMakeRect(0, 0, size.width, size.height)
        
        // Get the best representation for the given size.
        guard let rep = self.bestRepresentation(for: frame, context: nil, hints: nil) else {
            return nil
        }
        
        // Create an empty image with the given size.
        let img = NSImage(size: size)
        
        // Set the drawing context and make sure to remove the focus before returning.
        img.lockFocus()
        defer { img.unlockFocus() }
        
        // Draw the new image
        if rep.draw(in: frame) {
            return img
        }
        
        // Return nil in case something went wrong.
        return nil
    }
    
    func fastResize(size:NSSize) -> NSImage? {
        
        guard let image = self.cgImage(forProposedRect: nil
                                       , context: nil, hints: nil) else {return nil}
        let context = CGContext(data: nil,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: image.bitsPerComponent,
                                bytesPerRow: 0,
                                space: image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!,
                                bitmapInfo: image.bitmapInfo.rawValue)
        context?.interpolationQuality = .high
        context?.draw(image, in: CGRect(origin: .zero, size: size))

        guard let scaledImage = context?.makeImage() else { return nil }

        return NSImage(cgImage: scaledImage, size: size)
    }
    
    ///  Copies the current image and resizes it to the size of the given NSSize, while
    ///  maintaining the aspect ratio of the original image.
    ///
    ///  - parameter size: The size of the new image.
    ///
    ///  - returns: The resized copy of the given image.
    func resizeWhileMaintainingAspectRatioToSize(size: NSSize) -> NSImage? {
        let newSize: NSSize
        
        let widthRatio  = size.width / self.width
        let heightRatio = size.height / self.height
        
        if widthRatio > heightRatio {
            newSize = NSSize(width: floor(self.width * widthRatio), height: floor(self.height * widthRatio))
        } else {
            newSize = NSSize(width: floor(self.width * heightRatio), height: floor(self.height * heightRatio))
        }
        
        return self.copy(size: newSize)
    }
    
    ///  Copies and crops an image to the supplied size.
    ///
    ///  - parameter size: The size of the new image.
    ///
    ///  - returns: The cropped copy of the given image.
    func crop(size: NSSize) -> NSImage? {
        // Resize the current image, while preserving the aspect ratio.
        guard let resized = self.resizeWhileMaintainingAspectRatioToSize(size: size) else {
            return nil
        }
        // Get some points to center the cropping area.
        let x = floor((resized.width - size.width) / 2)
        let y = floor((resized.height - size.height) / 2)
        
        // Create the cropping frame.
        let frame = NSMakeRect(x, y, size.width, size.height)
        
        // Get the best representation of the image for the given cropping frame.
        guard let rep = resized.bestRepresentation(for: frame, context: nil, hints: nil) else {
            return nil
        }
        
        // Create a new image with the new size
        let img = NSImage(size: size)
        
        img.lockFocus()
        defer { img.unlockFocus() }
        
        if rep.draw(in: NSMakeRect(0, 0, size.width, size.height),
                    from: frame,
                    operation: NSCompositingOperation.copy,
                    fraction: 1.0,
                    respectFlipped: false,
                    hints: [:]) {
            // Return the cropped image.
            return img
        }
        
        // Return nil in case anything fails.
        return nil
    }
    
    ///  Saves the PNG representation of the current image to the HD.
    ///
    /// - parameter url: The location url to which to write the png file.
    func savePNGRepresentationToURL(url: URL) throws {
        if let png = self.PNGRepresentation {
            try png.write(to: url, options: .atomicWrite)
        }
    }
    
    func putOnImage(backgroundImage:NSImage) -> NSImage {
        
        let newImage = NSImage(size: self.size)
        newImage.lockFocus()
        var newImageRect: CGRect = .zero
        newImageRect.size = newImage.size
        backgroundImage.draw(in: newImageRect)
        self.draw(in: newImageRect)
        newImage.unlockFocus()
        return newImage
    }
    
    static func imageWithColor(color:NSColor, size:NSSize) -> NSImage
    {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        color.drawSwatch(in: NSRect(x:0,y:0,width:size.width,height:size.height))
        newImage.unlockFocus()
        return newImage
    }

    func saveTofile(file:URL) {
        guard let imageData = self.tiffRepresentation else {return}
        let imageRep = NSBitmapImageRep(data:imageData)
        guard let data = imageRep?.representation(using: .png, properties: [:]) else {return}
        try? data.write(to: file)
    }
    
    func ciImage() -> CIImage? {
        
        guard let data = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: data) else {
            return nil
        }
        let ci = CIImage(bitmapImageRep: bitmap)
        return ci
    }

    func blurImage(radius:CGFloat) -> NSImage? {
        
        guard let ciImage = self.ciImage() else {return nil}
        guard let blurFilter = CIFilter(name: "CIBoxBlur") else {return self}
        blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
        blurFilter.setValue(radius, forKey: kCIInputRadiusKey)
        guard let outputImage = blurFilter.outputImage else {return self}
        return outputImage.toImage()
    }

}

extension CVPixelBuffer {
    
    func toImage() -> NSImage {
        let ciImage = CIImage.init(cvPixelBuffer: self)
        return ciImage.toImage()
    }
    
    func makeTransparentImage(maskBuffer:CVPixelBuffer) -> CIImage? {
        
        let fgrImage = CIImage.init(cvPixelBuffer: self)
        let maskImage = CIImage.init(cvPixelBuffer: maskBuffer)
        guard let maskFilter = CIFilter(name: "CIMaskToAlpha") else {return nil}
        maskFilter.setValue(maskImage, forKey: kCIInputImageKey)
        let alphaMaskImage = maskFilter.outputImage
        guard let blendFilter = CIFilter(name: "CIBlendWithAlphaMask") else {return nil}
        blendFilter.setValue(fgrImage, forKey: kCIInputImageKey)
        blendFilter.setValue(alphaMaskImage, forKey: kCIInputMaskImageKey)
        guard let outImage = blendFilter.outputImage else {return nil}
        return outImage
    }
}

extension CIImage {
    
    func toImage() -> NSImage {
        
        let rep = NSCIImageRep(ciImage: self)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        return nsImage
    }
}

//https://github.com/hollance/CoreMLHelpers/blob/master/CoreMLHelpers/CGImage%2BCVPixelBuffer.swiftimport VideoToolbox

extension CGImage {
  /**
    Creates a new CGImage from a CVPixelBuffer.
    - Note: Not all CVPixelBuffer pixel formats support conversion into a
            CGImage-compatible pixel format.
  */
  public static func create(pixelBuffer: CVPixelBuffer) -> CGImage? {
    var cgImage: CGImage?
    VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
    return cgImage
  }

}
