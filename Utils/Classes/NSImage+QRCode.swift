
import Foundation

extension NSImage {
    
    public static func qrImage(string: String, imageSize: CGFloat) -> NSImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
    
        filter.setDefaults()
        let data = string.data(using: .utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        
        guard let outPutImage = filter.outputImage else {
            return nil
        }
        
        let extent = outPutImage.extent.integral
        let scale = min(imageSize / extent.width, imageSize / extent.height)
        let width = (Int)(extent.width * scale)
        let height = (Int)(extent.height * scale)
        let cs = CGColorSpaceCreateDeviceGray()
        
        guard let bitmapRef = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: cs, bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
            return nil
        }
        
        let context = CIContext(options: nil)
        
        guard let bitmapImage = context.createCGImage(outPutImage, from: extent) else {
            return nil
        }
        
        bitmapRef.interpolationQuality = CGInterpolationQuality.none
        bitmapRef.scaleBy(x: scale, y: scale)
        bitmapRef.draw(bitmapImage, in: extent)

        guard let scaledImage = bitmapRef.makeImage() else {
            return nil
        }
        
        var imageRect = CGRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0)
        
        imageRect.size.height = CGFloat(integerLiteral: scaledImage.height)
        imageRect.size.width = CGFloat(integerLiteral: scaledImage.width)
        
        let newImage = NSImage(size: imageRect.size)
        newImage.lockFocus()
        
        guard let imageContext = NSGraphicsContext.current?.cgContext else {
            return nil
        }
        
        imageContext.draw(scaledImage, in: imageRect)
        newImage.unlockFocus()
        
        return newImage;
    }
    
}
