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
    var blurImageViews = [UIImageView]() // updated property

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    func setupCamera() {
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
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
        previewLayer.frame = view.bounds
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let image = CIImage(cvPixelBuffer: pixelBuffer)

        let options: [String: Any] = [CIDetectorAccuracy: CIDetectorAccuracyHigh,
                                      CIDetectorMaxFeatureCount: 10]

        let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options)

        let faces = detector?.features(in: image)

        DispatchQueue.main.async {
            for imageView in self.blurImageViews {
                imageView.removeFromSuperview()
            }

            if self.blurEnabled {
                let blurEffect = UIBlurEffect(style: .regular)
                for face in faces as? [CIFaceFeature] ?? [] {
                    let imageView = UIImageView()
                    imageView.contentMode = .scaleAspectFill
                    let blurView = UIVisualEffectView(effect: blurEffect)
                    blurView.frame = face.bounds
                    imageView.addSubview(blurView)
                    imageView.frame = face.bounds
                    self.view.addSubview(imageView)
                    self.blurImageViews.append(imageView)
                }
            }
        }
    }

}
