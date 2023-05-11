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
        let blurButton = UIButton(type: .system)
        blurButton.setTitle("Toggle Blur", for: .normal)
        blurButton.addTarget(self, action: #selector(blurButtonTapped(_:)), for: .touchUpInside)
        blurButton.frame = CGRect(x: 16, y: 516, width: 120, height: 44) // Adjust position and size as desired
        view.addSubview(blurButton)
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

        DispatchQueue.main.async {
            for face in faces as! [CIFaceFeature] {
                let faceBounds = face.bounds
                let x = faceBounds.origin.x / image.extent.size.width
                let y = faceBounds.origin.y / image.extent.size.height
                let width = faceBounds.size.width / image.extent.size.width
                let height = faceBounds.size.height / image.extent.size.height
                let faceRect = CGRect(x: x, y: y, width: width, height: height)

                if self.blurEnabled {
                    let blurEffect = UIBlurEffect(style: .regular)
                    let blurView = UIVisualEffectView(effect: blurEffect)
                    blurView.frame = faceRect
                    self.view.addSubview(blurView)
                    self.blurView = blurView
                } else {
                    self.blurView?.removeFromSuperview()
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


