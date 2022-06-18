//
//  Composer.swift
//  VideoComposerTest
//
//  Created by Alexander Ivkin on 6/18/22.
//

import Foundation
import AVFoundation
import UIKit

func compose() {
    let url = Bundle.main.url(forResource: "test-video", withExtension: "mov")!
    let asset = AVURLAsset(url: url)
    let assetTrack = asset.tracks(withMediaType: .video).first!
    
    
    let composition = AVMutableComposition()
    guard let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
        print("cannot create track")
        return
    }
    
    do {
        let timeRange = CMTimeRange(start: .zero, duration: assetTrack.timeRange.duration)
        try compositionTrack.insertTimeRange(timeRange, of: assetTrack, at: .zero)
    } catch {
        print("Error: \(error)")
        return
    }
    
    let videoSize: CGSize = CGSize(width: assetTrack.naturalSize.width, height: assetTrack.naturalSize.height)
    let videoLayer = CALayer()
    videoLayer.frame = CGRect(origin: .zero, size: videoSize)
    let overlayLayer = CALayer()
    overlayLayer.frame = CGRect(origin: .zero, size: videoSize)
    let outputLayer = CALayer()
    outputLayer.frame = CGRect(origin: .zero, size: videoSize)
    outputLayer.addSublayer(videoLayer)
    outputLayer.addSublayer(overlayLayer)
    outputLayer.addSublayer(createWatermark(videoSize: videoSize))
    let videoComposition = AVMutableVideoComposition()
    videoComposition.renderSize = videoSize
    let frameRate: Int32 = max(Int32(assetTrack.nominalFrameRate), 30)
    videoComposition.frameDuration = CMTime(value: 1, timescale: frameRate)
    videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: outputLayer)
    
    let instruction = AVMutableVideoCompositionInstruction()
    instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)
    videoComposition.instructions = [instruction]
    let layerInstruction = compositionLayerInstruction(for: compositionTrack, assetTrack: assetTrack)
    instruction.layerInstructions = [layerInstruction]
    
    
    
    guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
    else {
        print("Cannot create export session.")
        return
    }
    
    let videoName = UUID().uuidString
    let exportURL = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(videoName)
        .appendingPathExtension("mov")
    
    export.videoComposition = videoComposition
    export.outputFileType = .mov
    export.outputURL = exportURL
    
    export.exportAsynchronously {
        DispatchQueue.main.async {
            switch export.status {
            case .completed:
                print("Exported to \(exportURL)")
            default:
                print("Error: \(export.error?.localizedDescription ?? "unknown")")
                break
            }
        }
    }
}

private func compositionLayerInstruction(for track: AVCompositionTrack, assetTrack: AVAssetTrack) -> AVMutableVideoCompositionLayerInstruction {
    let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
    let transform = CGAffineTransform.identity
    instruction.setTransform(transform, at: .zero)
    return instruction
}

private func createWatermark(videoSize: CGSize) -> CALayer {
    let layer = CALayer()
    let image = UIImage(named: "logo_acetrace_shadow.png")!
    
    let scale =  videoSize.width / image.size.width / 12
    let width = image.size.width * scale
    let height = image.size.height * scale
    
    layer.frame = CGRect(
        x: 0.5 * width,
        y: videoSize.height - 1.5 * height,
        width: width,
        height: height)
    
    layer.contents = image.cgImage
    layer.opacity = 0.9
    return layer
}
