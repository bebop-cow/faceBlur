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
    var blurEnabled: Bool = false
    var blurView: UIVisualEffectView!

    override func viewDidLoad() {
        super.viewDidLoad()
        blurView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurView)

        setupCamera()
    }

    func setupCamera() {
        
        session = AVCaptureSession()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }

        session.addInput(input)
        session.startRunning()

        

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        session.addOutput(output)
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let image = CIImage(cvPixelBuffer: pixelBuffer)

        let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let faces = detector?.features(in: image)

        print("Number of faces detected: \(faces?.count ?? 0)")

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
                print("Face detected!")
                let faceBounds = face.bounds
                let x = faceBounds.origin.x / image.extent.size.width
                let y = faceBounds.origin.y / image.extent.size.height
                let width = faceBounds.size.width / image.extent.size.width
                let height = faceBounds.size.height / image.extent.size.height
                let faceRect = CGRect(x: x, y: y, width: width, height: height)

                if self.blurEnabled {
                    self.blurView?.frame = faceRect
                } else {
                    self.blurView?.frame = self.view.bounds
                }
            }
        }
    }



  
    @IBAction func blurButtonTapped(_ sender: UIButton) {
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


