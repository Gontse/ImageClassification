//
//  ViewController.swift
//  ImageClassification
//
//  Created by Gontse on 2023/10/25.
//

import AVKit
import CoreML
import Vision

final class ViewController: UIViewController {
  
  @IBOutlet private weak var predictionLabel: UILabel!
  @IBOutlet private weak var confidenceLabel: UILabel!
  @IBOutlet private weak var imageView: UIImageView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupSession()
  }
  
  private func setupSession() {
    guard let device = AVCaptureDevice.default(for: .video),
          let input = try? AVCaptureDeviceInput(device: device) else { return }
    
    let session = AVCaptureSession()
    session.sessionPreset = .hd4K3840x2160
    
    let previewLayer = AVCaptureVideoPreviewLayer(session: session)
    previewLayer.frame = view.frame
    previewLayer.videoGravity = .resizeAspectFill
    imageView.layer.addSublayer(previewLayer)
    
    let output = AVCaptureVideoDataOutput()
    output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
    
    session.addOutput(output)
    session.addInput(input)
    DispatchQueue.main.async {
      session.startRunning()
    }
  }
  
}

// MARK: - AVCaptureSession

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
          let model = try? VNCoreMLModel(for: MobileNet(configuration: MLModelConfiguration()).model) else { return }
    
    let request = VNCoreMLRequest(model: model) { (data, error) in
    
      guard let results = data.results as? [VNClassificationObservation],
      let firstObject = results.first else { return }
      
      if firstObject.confidence * 100 >= 20 {
        DispatchQueue.main.async {
          self.predictionLabel.text = firstObject.identifier.capitalized
          self.confidenceLabel.text = String(firstObject.confidence) + "%"
        }
      } else {
        DispatchQueue.main.async {
          self.predictionLabel.text = "--"
          self.confidenceLabel.text = "--"
        }
      }
    }
    
    try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
  }
  
}
