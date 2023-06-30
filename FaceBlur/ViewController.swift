//
//  ViewController.swift
//  FaceBlur
//
//  Created by Tyrone  Fernandes on 5/2/23.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {
    
    // MARK: - Variables
     
     private var drawings: [CAShapeLayer] = []
     
     private let videoDataOutput = AVCaptureVideoDataOutput()
     private let captureSession = AVCaptureSession()
     
     /// Using `lazy` keyword because the `captureSession` needs to be loaded before we can use the preview layer.
     private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
     
     // MARK: - Lifecycle
     
     override func viewDidLoad() {
       super.viewDidLoad()
       // Do any additional setup after loading the view.
       
       addCameraInput()
       showCameraFeed()
       
       getCameraFrames()
       captureSession.startRunning()
     }
     
     /// The account for when the container's `view` changes.
     override func viewDidLayoutSubviews() {
       super.viewDidLayoutSubviews()
       
       previewLayer.frame = view.frame
     }
