/*
 * Adapted from Objective-C version: https://github.com/twilio/video-ios-affectiva/blob/ed2e864324c40ad25e5a06cc2b05298b03caed09/EmoCall/I420Converter.m
 */

import Accelerate
import Foundation
import UIKit
import VideoToolbox
import WebRTC

public class I420Converter {
    private var conversionInfo: UnsafeMutablePointer<vImage_YpCbCrToARGB>?
    private var pixelBufferPool: CVPixelBufferPool?
    private var poolWidth: Int = 0
    private var poolHeight: Int = 0

    init() {
        let error = prepareForAccelerateConversion()

        guard error == kvImageNoError else {
            print("Failed to prepare for accelerate conversion: \(error)")
            return
        }
    }

    deinit {
        unprepareForAccelerateConversion()
    }

    /// Creates a pixel buffer pool with specified dimensions
    /// - Parameters:
    ///   - width: Width of the pixel buffers
    ///   - height: Height of the pixel buffers
    public func createPixelBufferPool(width: Int, height: Int) {
        poolWidth = width
        poolHeight = height

        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:],
        ]

        var pool: CVPixelBufferPool?
        let ret = CVPixelBufferPoolCreate(
            kCFAllocatorDefault,
            nil,
            pixelBufferAttributes as CFDictionary,
            &pool
        )

        if ret != kCVReturnSuccess {
            print("Error creating pixel buffer pool: \(ret)")
            pixelBufferPool = nil
        } else {
            pixelBufferPool = pool
        }
    }

    /// Converts an I420Buffer to a CVPixelBuffer using accelerated conversion
    /// - Parameter buffer: The I420Buffer to convert
    /// - Returns: CVPixelBuffer or nil if conversion fails
    public func convertToCVPixelBuffer(from buffer: RTCI420BufferProtocol) -> CVPixelBuffer? {
        guard conversionInfo != nil else {
            print("\(#function) failed. I420Converter failed to initialize.")
            return nil
        }

        let width = Int(buffer.width)
        let height = Int(buffer.height)

        if pixelBufferPool == nil || poolWidth != width || poolHeight != height {
            createPixelBufferPool(width: width, height: height)
        }

        guard let pool = pixelBufferPool else {
            return nil
        }

        var pixelBuffer: CVPixelBuffer!
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer)

        guard status == kCVReturnSuccess else {
            return nil
        }

        let error = convertFrameVImageYUV(buffer, toBuffer: pixelBuffer)

        if error != kvImageNoError {
            print("\(#function): error during conversion: \(error)")
            return nil
        }

        return pixelBuffer
    }

    // MARK: - Private Methods

    /// Prepares the converter for accelerated conversion using vImage
    /// - Returns: vImage_Error indicating success or failure
    private func prepareForAccelerateConversion() -> vImage_Error {
        // Setup the YpCbCr to ARGB conversion.
        if conversionInfo != nil {
            return kvImageNoError
        }

        // I420 uses limited range.
        let pixelRange = vImage_YpCbCrPixelRange(
            Yp_bias: 16,
            CbCr_bias: 128,
            YpRangeMax: 235,
            CbCrRangeMax: 240,
            YpMax: 255,
            YpMin: 0,
            CbCrMax: 255,
            CbCrMin: 0
        )

        let outInfo = UnsafeMutablePointer<vImage_YpCbCrToARGB>.allocate(capacity: 1)
        let inType = kvImage420Yp8_Cb8_Cr8
        let outType = kvImageARGB8888

        var pixelRangeCopy = pixelRange
        let error = vImageConvert_YpCbCrToARGB_GenerateConversion(
            kvImage_YpCbCrToARGBMatrix_ITU_R_601_4,
            &pixelRangeCopy,
            outInfo,
            inType,
            outType,
            vImage_Flags(kvImagePrintDiagnosticsToConsole)
        )

        if error == kvImageNoError {
            conversionInfo = outInfo
        } else {
            outInfo.deallocate()
        }

        return error
    }

    /// Cleans up accelerated conversion resources
    private func unprepareForAccelerateConversion() {
        if let info = conversionInfo {
            info.deallocate()
            conversionInfo = nil
        }

        pixelBufferPool = nil
    }

    /// Performs the actual conversion from I420 to pixel buffer using vImage
    /// - Parameters:
    ///   - buffer: Source I420Buffer
    ///   - pixelBufferRef: Destination CVPixelBuffer
    /// - Returns: vImage_Error indicating success or failure
    private func convertFrameVImageYUV(_ buffer: RTCI420BufferProtocol, toBuffer pixelBufferRef: CVPixelBuffer)
        -> vImage_Error
    {
        guard let conversionInfo = conversionInfo else {
            return vImage_Error(kvImageInvalidParameter)
        }

        // Compute info for I420 source
        let width = vImagePixelCount(buffer.width)
        let height = vImagePixelCount(buffer.height)
        let subsampledWidth = vImagePixelCount(buffer.chromaWidth)
        let subsampledHeight = vImagePixelCount(buffer.chromaHeight)

        let yPlane = buffer.dataY
        let uPlane = buffer.dataU
        let vPlane = buffer.dataV
        let yStride = Int(buffer.strideY)
        let uStride = Int(buffer.strideU)
        let vStride = Int(buffer.strideV)

        // Create vImage buffers to represent each of the Y, U, and V planes
        var yPlaneBuffer = vImage_Buffer(
            data: UnsafeMutableRawPointer(mutating: yPlane),
            height: height,
            width: width,
            rowBytes: yStride
        )

        var uPlaneBuffer = vImage_Buffer(
            data: UnsafeMutableRawPointer(mutating: uPlane),
            height: subsampledHeight,
            width: subsampledWidth,
            rowBytes: uStride
        )

        var vPlaneBuffer = vImage_Buffer(
            data: UnsafeMutableRawPointer(mutating: vPlane),
            height: subsampledHeight,
            width: subsampledWidth,
            rowBytes: vStride
        )

        // Create a vImage buffer for the destination pixel buffer
        CVPixelBufferLockBaseAddress(pixelBufferRef, CVPixelBufferLockFlags(rawValue: 0))
        defer { CVPixelBufferUnlockBaseAddress(pixelBufferRef, CVPixelBufferLockFlags(rawValue: 0)) }

        guard let pixelBufferData = CVPixelBufferGetBaseAddress(pixelBufferRef) else {
            return vImage_Error(kvImageInvalidParameter)
        }

        let rowBytes = CVPixelBufferGetBytesPerRow(pixelBufferRef)

        var destinationImageBuffer = vImage_Buffer(
            data: pixelBufferData,
            height: height,
            width: width,
            rowBytes: rowBytes
        )

        // Do the conversion
        let permuteMap: [UInt8] = [3, 2, 1, 0]  // BGRA

        let convertError = vImageConvert_420Yp8_Cb8_Cr8ToARGB8888(
            &yPlaneBuffer,
            &uPlaneBuffer,
            &vPlaneBuffer,
            &destinationImageBuffer,
            conversionInfo,
            permuteMap,
            255,
            vImage_Flags(kvImageNoFlags)
        )

        return convertError
    }
}
