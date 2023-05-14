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
        
        // Setup AVCaptureSession
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        // Setup camera device
        let cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        guard let cameraInput = try? AVCaptureDeviceInput(device: cameraDevice!),
              captureSession.canAddInput(cameraInput) else { return }
        captureSession.addInput(cameraInput)
        
        // Setup video output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video_queue"))
        guard captureSession.canAddOutput(videoOutput) else { return }
        captureSession.addOutput(videoOutput)
        
        // Setup video preview layer
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer)
        
        // Start running the capture session
        captureSession.startRunning()
    }
    
    
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        
        let options: [String: Any] = [CIDetectorAccuracy: CIDetectorAccuracyHigh,
                               CIDetectorMaxFeatureCount: 10]
        
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options)
        
        let faces = detector?.features(in: image)
        
        DispatchQueue.main.async {
            if self.blurEnabled {
                self.blurView?.removeFromSuperview() // Remove previously added blur view if it exists
                let blurEffect = UIBlurEffect(style: .regular)
                let blurView = UIVisualEffectView(effect: blurEffect)
                self.view.addSubview(blurView)
                self.blurView = blurView
            } else {
                self.blurView?.removeFromSuperview()
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
                    self.blurView = UIVisualEffectView()
                    self.blurView?.frame = faceRect
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
