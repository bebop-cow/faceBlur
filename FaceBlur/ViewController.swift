//
//  ViewController.swift
//  FaceBlur
//
//  Created by Tyrone  Fernandes on 5/2/23.
//

import UIKit
import AVFoundation
import CoreImage

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var session: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var videoDataOutput: AVCaptureVideoDataOutput!
    var blurEnabled: Bool = false
    var blurView: UIVisualEffectView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        view.addSubview(blurView)
        self.blurView = blurView // Replace with self.blurView

    }
    
    
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        
        let options: [String: Any] = [CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorMaxFeatureCount: 10]
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options)
        let faces = detector?.features(in: image)
        
        DispatchQueue.main.async {
            if self.blurEnabled {
                // Add blur effect view to the root view if it doesn't exist
                if self.blurView == nil {
                    let blurEffect = UIBlurEffect(style: .regular)
                    let blurView = UIVisualEffectView(effect: blurEffect)
                    blurView.frame = self.view.bounds
                    self.view.addSubview(blurView)
                    self.blurView = blurView
                }
            } else {
                self.blurView?.removeFromSuperview()
                self.blurView = nil
            }
            
            if let face = faces?.first as? CIFaceFeature {
                let faceBounds = face.bounds
                let x = faceBounds.origin.x / image.extent.size.width
                let y = faceBounds.origin.y / image.extent.size.height
                let width = faceBounds.size.width / image.extent.size.width
                let height = faceBounds.size.height / image.extent.size.height
                let faceRect = CGRect(x: x, y: y, width: width, height: height)
                
                if self.blurEnabled {
                    let filter = CIFilter(name: "CIGaussianBlur")!
                    filter.setValue(image, forKey: kCIInputImageKey)
                    let radius = min(faceRect.width, faceRect.height) * 0.5 * 10
                    filter.setValue(radius, forKey: kCIInputRadiusKey)
                    let blurredImage = filter.outputImage!

                    let context = CIContext()
                    let cgImage = context.createCGImage(blurredImage, from: image.extent)!

                    let imageView = UIImageView(image: UIImage(cgImage: cgImage))
                    imageView.frame = faceRect
                    self.view.addSubview(imageView)
                    self.blurView = imageView // Replace with self.blurView
                } else {
                    self.blurView?.frame = self.view.bounds

                }
            }
        }
     
        func blurButtonTapped(_ sender: UIButton) {
            blurEnabled = !blurEnabled
            if blurEnabled {
                // Create a UIBlurEffectView and add it to the view
                let blurEffect = UIBlurEffect(style: .regular)
                let blurView = UIVisualEffectView(effect: blurEffect)
                view.addSubview(blurView)
                blurView.frame = view.bounds
                self.blurView = blurView
            } else {
                // Remove the UIBlurEffectView from the view
                self.blurView?.removeFromSuperview()
                self.blurView = nil
            }
        }
        
        
        
    }
    
}
