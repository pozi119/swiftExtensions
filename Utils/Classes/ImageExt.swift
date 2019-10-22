//
//  UIImageExt.swift
//  ValoKit
//
//  Created by Valo on 2016/12/2.
//
//

import Foundation

#if os(iOS) || os(tvOS)

    // MARK: alpha

    public extension UIImage {
        func hasAlpha() -> Bool {
            let alpha: CGImageAlphaInfo = (cgImage)!.alphaInfo
            return
                alpha == CGImageAlphaInfo.first ||
                alpha == CGImageAlphaInfo.last ||
                alpha == CGImageAlphaInfo.premultipliedFirst ||
                alpha == CGImageAlphaInfo.premultipliedLast
        }

        func imageWithAlpha() -> UIImage {
            if hasAlpha() {
                return self
            }

            let imageRef: CGImage = cgImage!
            let width = imageRef.width
            let height = imageRef.height

            // The bitsPerComponent and bitmapInfo values are hard-coded to prevent an "unsupported parameter combination" error
            let offscreenContext: CGContext = CGContext(
                data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                space: imageRef.colorSpace!,
                bitmapInfo: 0 /* CGImageByteOrderInfo.orderMask.rawValue */ | CGImageAlphaInfo.premultipliedFirst.rawValue
            )!

            // Draw the image into the context and retrieve the new image, which will now have an alpha layer
            offscreenContext.draw(imageRef, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
            let imageRefWithAlpha: CGImage = offscreenContext.makeImage()!

            return UIImage(cgImage: imageRefWithAlpha)
        }

        func transparentBorderImage(_ borderSize: Int) -> UIImage {
            let image = imageWithAlpha()

            let newRect = CGRect(
                x: 0, y: 0,
                width: image.size.width + CGFloat(borderSize) * 2,
                height: image.size.height + CGFloat(borderSize) * 2
            )

            // Build a context that's the same dimensions as the new size
            let bitmap: CGContext = CGContext(
                data: nil,
                width: Int(newRect.size.width), height: Int(newRect.size.height),
                bitsPerComponent: (cgImage)!.bitsPerComponent,
                bytesPerRow: 0,
                space: (cgImage)!.colorSpace!,
                bitmapInfo: (cgImage)!.bitmapInfo.rawValue
            )!

            // Draw the image in the center of the context, leaving a gap around the edges
            let imageLocation = CGRect(x: CGFloat(borderSize), y: CGFloat(borderSize), width: image.size.width, height: image.size.height)
            bitmap.draw(cgImage!, in: imageLocation)
            let borderImageRef: CGImage = bitmap.makeImage()!

            // Create a mask to make the border transparent, and combine it with the image
            let maskImageRef: CGImage = newBorderMask(borderSize, size: newRect.size)
            let transparentBorderImageRef: CGImage = borderImageRef.masking(maskImageRef)!
            return UIImage(cgImage: transparentBorderImageRef)
        }

        fileprivate func newBorderMask(_ borderSize: Int, size: CGSize) -> CGImage {
            let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceGray()

            // Build a context that's the same dimensions as the new size
            let maskContext: CGContext = CGContext(
                data: nil,
                width: Int(size.width), height: Int(size.height),
                bitsPerComponent: 8, // 8-bit grayscale
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo().rawValue | CGImageAlphaInfo.none.rawValue
            )!

            // Start with a mask that's entirely transparent
            maskContext.setFillColor(UIColor.black.cgColor)
            maskContext.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))

            // Make the inner part (within the border) opaque
            maskContext.setFillColor(UIColor.white.cgColor)
            maskContext.fill(CGRect(
                x: CGFloat(borderSize),
                y: CGFloat(borderSize),
                width: size.width - CGFloat(borderSize) * 2,
                height: size.height - CGFloat(borderSize) * 2)
            )

            // Get an image of the context
            return maskContext.makeImage()!
        }
    }

    // MARK: resize

    public extension UIImage {
        // Returns a copy of this image that is cropped to the given bounds.
        // The bounds will be adjusted using CGRectIntegral.
        // This method ignores the image's imageOrientation setting.
        func croppedImage(_ bounds: CGRect) -> UIImage {
            let imageRef: CGImage = (cgImage)!.cropping(to: bounds)!
            return UIImage(cgImage: imageRef)
        }

        func thumbnailImage(_ thumbnailSize: Int, transparentBorder borderSize: Int, cornerRadius: Int, interpolationQuality quality: CGInterpolationQuality) -> UIImage {
            let resizedImage = resizedImageWithContentMode(.scaleAspectFill, bounds: CGSize(width: CGFloat(thumbnailSize), height: CGFloat(thumbnailSize)), interpolationQuality: quality)

            // Crop out any part of the image that's larger than the thumbnail size
            // The cropped rect must be centered on the resized image
            // Round the origin points so that the size isn't altered when CGRectIntegral is later invoked
            let cropRect = CGRect(
                x: round((resizedImage.size.width - CGFloat(thumbnailSize)) / 2),
                y: round((resizedImage.size.height - CGFloat(thumbnailSize)) / 2),
                width: CGFloat(thumbnailSize),
                height: CGFloat(thumbnailSize)
            )

            let croppedImage = resizedImage.croppedImage(cropRect)
            let transparentBorderImage = borderSize != 0 ? croppedImage.transparentBorderImage(borderSize) : croppedImage

            return transparentBorderImage.roundedCornerImage(cornerSize: cornerRadius, borderSize: borderSize)
        }

        // Returns a rescaled copy of the image, taking into account its orientation
        // The image will be scaled disproportionately if necessary to fit the bounds specified by the parameter
        func resizedImage(_ newSize: CGSize, interpolationQuality quality: CGInterpolationQuality) -> UIImage {
            var drawTransposed: Bool

            switch imageOrientation {
            case .left, .leftMirrored, .right, .rightMirrored:
                drawTransposed = true
            default:
                drawTransposed = false
            }

            return resizedImage(
                newSize,
                transform: transformForOrientation(newSize),
                drawTransposed: drawTransposed,
                interpolationQuality: quality
            )
        }

        func resizedImageWithContentMode(_ contentMode: UIView.ContentMode, bounds: CGSize, interpolationQuality quality: CGInterpolationQuality) -> UIImage {
            let horizontalRatio = bounds.width / size.width
            let verticalRatio = bounds.height / size.height
            var ratio: CGFloat = 1

            switch contentMode {
            case .scaleAspectFill:
                ratio = max(horizontalRatio, verticalRatio)
            case .scaleAspectFit:
                ratio = min(horizontalRatio, verticalRatio)
            default:
                fatalError("Unsupported content mode \(contentMode)")
            }

            let newSize: CGSize = CGSize(width: size.width * ratio, height: size.height * ratio)
            return resizedImage(newSize, interpolationQuality: quality)
        }

        fileprivate func normalizeBitmapInfo(_ bI: CGBitmapInfo) -> UInt32 {
            var alphaInfo: UInt32 = bI.rawValue & CGBitmapInfo.alphaInfoMask.rawValue

            if alphaInfo == CGImageAlphaInfo.last.rawValue {
                alphaInfo = CGImageAlphaInfo.premultipliedLast.rawValue
            }

            if alphaInfo == CGImageAlphaInfo.first.rawValue {
                alphaInfo = CGImageAlphaInfo.premultipliedFirst.rawValue
            }

            var newBI: UInt32 = bI.rawValue & ~CGBitmapInfo.alphaInfoMask.rawValue

            newBI |= alphaInfo

            return newBI
        }

        fileprivate func resizedImage(_ newSize: CGSize, transform: CGAffineTransform, drawTransposed transpose: Bool, interpolationQuality quality: CGInterpolationQuality) -> UIImage {
            let newRect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height).integral
            let transposedRect = CGRect(x: 0, y: 0, width: newRect.size.height, height: newRect.size.width)
            let imageRef: CGImage = cgImage!

            // Build a context that's the same dimensions as the new size
            let bitmap: CGContext = CGContext(
                data: nil,
                width: Int(newRect.size.width),
                height: Int(newRect.size.height),
                bitsPerComponent: imageRef.bitsPerComponent,
                bytesPerRow: 0,
                space: imageRef.colorSpace!,
                bitmapInfo: normalizeBitmapInfo(imageRef.bitmapInfo)
            )!

            // Rotate and/or flip the image if required by its orientation
            bitmap.concatenate(transform)

            // Set the quality level to use when rescaling
            bitmap.interpolationQuality = quality

            // Draw into the context; this scales the image
            bitmap.draw(imageRef, in: transpose ? transposedRect : newRect)

            // Get the resized image from the context and a UIImage
            let newImageRef: CGImage = bitmap.makeImage()!
            return UIImage(cgImage: newImageRef)
        }

        fileprivate func transformForOrientation(_ newSize: CGSize) -> CGAffineTransform {
            var transform: CGAffineTransform = CGAffineTransform.identity

            switch imageOrientation {
            case .down, .downMirrored:
                // EXIF = 3 / 4
                transform = transform.translatedBy(x: newSize.width, y: newSize.height)
                transform = transform.rotated(by: CGFloat(Double.pi))
            case .left, .leftMirrored:
                // EXIF = 6 / 5
                transform = transform.translatedBy(x: newSize.width, y: 0)
                transform = transform.rotated(by: CGFloat(Double.pi / 2))
            case .right, .rightMirrored:
                // EXIF = 8 / 7
                transform = transform.translatedBy(x: 0, y: newSize.height)
                transform = transform.rotated(by: -CGFloat(Double.pi / 2))
            default:
                break
            }

            switch imageOrientation {
            case .upMirrored, .downMirrored:
                // EXIF = 2 / 4
                transform = transform.translatedBy(x: newSize.width, y: 0)
                transform = transform.scaledBy(x: -1, y: 1)
            case .leftMirrored, .rightMirrored:
                // EXIF = 5 / 7
                transform = transform.translatedBy(x: newSize.height, y: 0)
                transform = transform.scaledBy(x: -1, y: 1)
            default:
                break
            }

            return transform
        }
    }

    // MARK: roundCorner

    public extension UIImage {
        // Creates a copy of this image with rounded corners
        // If borderSize is non-zero, a transparent border of the given size will also be added
        // Original author: Björn Sållarp. Used with permission. See: http://blog.sallarp.com/iphone-uiimage-round-corners/
        func roundedCornerImage(cornerSize: Int, borderSize: Int) -> UIImage {
            // If the image does not have an alpha layer, add one
            let image = imageWithAlpha()

            // Build a context that's the same dimensions as the new size
            let context: CGContext = CGContext(
                data: nil,
                width: Int(image.size.width),
                height: Int(image.size.height),
                bitsPerComponent: (image.cgImage)!.bitsPerComponent,
                bytesPerRow: 0,
                space: (image.cgImage)!.colorSpace!,
                bitmapInfo: (image.cgImage)!.bitmapInfo.rawValue
            )!

            // Create a clipping path with rounded corners
            context.beginPath()
            addRoundedRectToPath(
                CGRect(
                    x: CGFloat(borderSize),
                    y: CGFloat(borderSize),
                    width: image.size.width - CGFloat(borderSize) * 2,
                    height: image.size.height - CGFloat(borderSize) * 2),
                context: context,
                ovalWidth: CGFloat(cornerSize),
                ovalHeight: CGFloat(cornerSize)
            )
            context.closePath()
            context.clip()

            // Draw the image to the context; the clipping path will make anything outside the rounded rect transparent
            context.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))

            // Create a CGImage from the context
            let clippedImage: CGImage = context.makeImage()!

            // Create a UIImage from the CGImage
            return UIImage(cgImage: clippedImage)
        }

        // Adds a rectangular path to the given context and rounds its corners by the given extents
        // Original author: Björn Sållarp. Used with permission. See: http://blog.sallarp.com/iphone-uiimage-round-corners/
        fileprivate func addRoundedRectToPath(_ rect: CGRect, context: CGContext, ovalWidth: CGFloat, ovalHeight: CGFloat) {
            if ovalWidth == 0 || ovalHeight == 0 {
                context.addRect(rect)
                return
            }

            context.saveGState()
            context.translateBy(x: rect.minX, y: rect.minY)
            context.scaleBy(x: ovalWidth, y: ovalHeight)
            let fw = rect.width / ovalWidth
            let fh = rect.height / ovalHeight
            context.move(to: CGPoint(x: fw, y: fh / 2))
            context.addArc(tangent1End: CGPoint(x: fw, y: fh), tangent2End: CGPoint(x: fw / 2, y: fh), radius: 1)
            context.addArc(tangent1End: CGPoint(x: 0, y: fh), tangent2End: CGPoint(x: 0, y: fh / 2), radius: 1)
            context.addArc(tangent1End: CGPoint(x: 0, y: 0), tangent2End: CGPoint(x: fw / 2, y: 0), radius: 1)
            context.addArc(tangent1End: CGPoint(x: fw, y: 0), tangent2End: CGPoint(x: fw, y: fh / 2), radius: 1)

            context.closePath()
            context.restoreGState()
        }
    }

    // MARK: color

    extension UIImage {
        class func image(with color: UIColor, _ size: CGSize) -> UIImage? {
            let rect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
            UIGraphicsBeginImageContext(size)
            let context = UIGraphicsGetCurrentContext()
            context?.setFillColor(color.cgColor)
            context?.fill(rect)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }

        func colored(with color: UIColor) -> UIImage? {
            UIGraphicsBeginImageContextWithOptions(size, false, scale)
            let context = UIGraphicsGetCurrentContext()
            context?.translateBy(x: 0, y: size.height)
            context?.scaleBy(x: 1.0, y: -1.0)
            context?.setBlendMode(.normal)
            let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            context?.clip(to: rect, mask: cgImage!)
            color.setFill()
            context?.fill(rect)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
    }
#endif
