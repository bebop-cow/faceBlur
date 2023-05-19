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
    
    var captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    var blurEnabled = false
    var blurImageViews = [UIImageView]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    func setupCamera() {
        let captureDevice = AVCaptureDevice.default(for: .video)
        guard let input = try? AVCaptureDeviceInput(device: captureDevice!), captureSession.canAddInput(input) else { return }
        captureSession.addInput(input)
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(output)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let previewLayer = previewLayer {
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        }
    }
    
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let image = CIImage(cvPixelBuffer: pixelBuffer)

        let options: [String: Any] = [CIDetectorAccuracy: CIDetectorAccuracyHigh,
                                      CIDetectorMaxFeatureCount: 10]

        let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options)

        let faces = detector?.features(in: image)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if self.blurEnabled {
                for imageView in self.blurImageViews {
                    imageView.removeFromSuperview()
                }
                self.blurImageViews.removeAll()

                if let features = faces as? [CIFaceFeature] {
                    for face in features {
                        let faceBounds = self.calculateImageViewFrame(for: face.bounds)

                        // Add yellow outline box
                        let outlineView = UIView(frame: faceBounds)
                        outlineView.layer.borderWidth = 2.0
                        outlineView.layer.borderColor = UIColor.yellow.cgColor
                        self.view.addSubview(outlineView)
                        print("Added outline view at \(faceBounds)")

                        let imageView = UIImageView()
                        imageView.contentMode = .scaleAspectFill
                        imageView.frame = faceBounds
                        self.view.addSubview(imageView)
                        self.blurImageViews.append(imageView)
                    }
                }
            } else {
                for imageView in self.blurImageViews {
                    imageView.removeFromSuperview()
                }
                self.blurImageViews.removeAll()
            }
            
            self.view.bringSubviewToFront(self.previewLayer)

            print("Number of detected faces: \(faces?.count ?? 0)")
        }
    }



    
    func calculateImageViewFrame(for faceBounds: CGRect) -> CGRect {
        let scaleX = view.bounds.width
        let scaleY = view.bounds.height
        let videoBox = videoPreviewBox(for: previewLayer.videoGravity, frameSize: view.bounds.size, apertureSize: faceBounds.size)
        
        var transform = CGAffineTransform.identity
        transform = CGAffineTransform(scaleX: videoBox.width / scaleX, y: videoBox.height / scaleY)
        transform = transform.translatedBy(x: videoBox.origin.x, y: videoBox.origin.y)
        transform = transform.scaledBy(x: videoBox.width, y: videoBox.height)
        
        let transformedBounds = faceBounds.applying(transform)
        return transformedBounds
    }

    
    func videoPreviewBox(for gravity: AVLayerVideoGravity, frameSize: CGSize, apertureSize: CGSize) -> CGRect {
        var videoBox = CGRect.zero
        let apertureRatio = apertureSize.height / apertureSize.width
        let viewRatio = frameSize.width / frameSize.height
        
        switch gravity {
        case .resize:
            videoBox.size.width = frameSize.width
            videoBox.size.height = frameSize.height
        case .resizeAspect:
            if viewRatio > apertureRatio {
                videoBox.size.width = frameSize.height * apertureRatio
                videoBox.size.height = frameSize.height
                videoBox.origin.x = (frameSize.width - videoBox.size.width) / 2
            } else {
                videoBox.size.width = frameSize.width
                videoBox.size.height = frameSize.width / apertureRatio
                videoBox.origin.y = (frameSize.height - videoBox.size.height) / 2
            }
        case .resizeAspectFill:
            if viewRatio > apertureRatio {
                videoBox.size.width = frameSize.width
                videoBox.size.height = frameSize.width / apertureRatio
                videoBox.origin.y = (frameSize.height - videoBox.size.height) / 2
            } else {
                videoBox.size.width = frameSize.height * apertureRatio
                videoBox.size.height = frameSize.height
                videoBox.origin.x = (frameSize.width - videoBox.size.width) / 2
            }
        default:
            break
        }
        
        return videoBox
    }
}
