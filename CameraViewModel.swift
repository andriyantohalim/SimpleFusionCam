//
//  CameraViewModel.swift
//  SimpleFusionCam
//
//  Created by Andriyanto Halim on 26/10/24.
//

import Foundation
import AVFoundation
import Combine
import UIKit
import Photos

class CameraViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    private var captureSession: AVCaptureMultiCamSession?
    private var photodevice: AVCaptureDevice?
    private var photoDeviceInput: AVCaptureDeviceInput?
    private var photoOutput: AVCapturePhotoOutput?
    private var zoomFactor: CGFloat = 1.0
    private var maxZoomFactor: CGFloat = 1.0 // Change based on device capabilities
    private var minZoomFactor: CGFloat = 1.0 // Change based on device capabilities
    private var locationManager: CLLocationManager?
    
    @Published var isPhotoSaved = false
    @Published var capturedImage: UIImage?
    @Published var focusPoint: CGPoint?
    @Published var touchPoint: CGPoint?
    @Published var lensDistance: Float?
    
    // Function to start the camera session
    func startSession() {
        captureSession = AVCaptureMultiCamSession()
        captureSession?.beginConfiguration()

        guard let captureSession = captureSession else { return }

        // Switch to back camera input (instead of front camera)
        guard let backCamera = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) else { return }
        
        maxZoomFactor = backCamera.maxAvailableVideoZoomFactor
        minZoomFactor = backCamera.minAvailableVideoZoomFactor
        

        do {
            let backCameraInput = try AVCaptureDeviceInput(device: backCamera)
            if captureSession.canAddInput(backCameraInput) {
                captureSession.addInput(backCameraInput)
                self.photodevice = backCamera
                self.photoDeviceInput = backCameraInput
            }

            // Preview layer
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            self.previewLayer = previewLayer

            // Photo output
            let photoOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
                self.photoOutput = photoOutput
            }

            captureSession.commitConfiguration()
            captureSession.startRunning()
        } catch {
            print("Error configuring back camera: \(error)")
        }
    }

    func UltraWideLens() {
        guard let device = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) else { return }
        let newZoomFactor = 1.0
        updateZoomFactor(device: device, factor: newZoomFactor)
    }
    
    func PrimeWideLens() {
        guard let device = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) else { return }
        let newZoomFactor = 2.0
        updateZoomFactor(device: device, factor: newZoomFactor)
    }
    
    func TelephotoLens() {
        guard let device = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) else { return }
        let newZoomFactor = 4.0
        updateZoomFactor(device: device, factor: newZoomFactor)
    }
    
    // Function to update zoom factor
    private func updateZoomFactor(device: AVCaptureDevice, factor: CGFloat) {
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = factor
            device.unlockForConfiguration()
            zoomFactor = factor
        } catch {
            print("Error updating zoom factor: \(error)")
        }
    }
    
    // MARK: - Focus
    func setFocus(to touchPoint: CGPoint, in frame: CGRect) {
        let focusPoint = previewLayer!.captureDevicePointConverted(fromLayerPoint: touchPoint)
        
        guard let photoDevice = photodevice else { return }
        do {
            try photoDevice.lockForConfiguration()
                        
            if photoDevice.isFocusModeSupported(.autoFocus) {
                photoDevice.focusPointOfInterest = focusPoint
                photoDevice.focusMode = .autoFocus
            }
            
            if photoDevice.isExposureModeSupported(.autoExpose) {
                photoDevice.exposurePointOfInterest = focusPoint
                photoDevice.exposureMode = .autoExpose
            }

            photoDevice.unlockForConfiguration()
            
            let lensDistance = photoDevice.lensPosition
            
            self.focusPoint = focusPoint
            self.touchPoint = touchPoint
            self.lensDistance = lensDistance

            // Re-enable autofocus after 1 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.resetFocusSettings()
                
                self.focusPoint = nil
                self.touchPoint = nil
            }
        } catch {
            print("Error focusing on point: \(error)")
        }
    }
    
    private func resetFocusSettings() {
        guard let photoDevice = photodevice else { return }
        
        do {
            try photoDevice.lockForConfiguration()
            
            if photoDevice.isFocusModeSupported(.continuousAutoFocus) {
                photoDevice.focusMode = .continuousAutoFocus
            }
            
            if photoDevice.isExposureModeSupported(.continuousAutoExposure) {
                photoDevice.exposureMode = .continuousAutoExposure
            }

            photoDevice.unlockForConfiguration()
        } catch {
            print("Error resetting focus settings: \(error)")
        }
    }

    
    // Function to capture photo
    func capturePhoto() {
        guard let photoOutput = photoOutput else { return }
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // MARK: - Haptic Feedback
    func lensSelectionHapticFeedback() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.prepare() // Prepares the feedback for a faster response
        feedbackGenerator.impactOccurred() // Trigger feedback
    }
    
    // MARK: - Helpers
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        return previewLayer
    }
    
}

extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        DispatchQueue.main.async {
            guard let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) else { return }
            
            // Save the captured image to the photo library
            self.savePhotoToLibrary(imageData)
//            self.saveImageToLibrary(image)
        }
    }
    
    // Save image to the photo library
    private func saveImageToLibrary(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                if success {
                    print("Photo saved successfully")
                } else if let error = error {
                    print("Error saving photo: \(error)")
                }
            }
        }
    }
    
    // MARK: - Photo Library
    private func savePhotoToLibrary(_ imageData: Data) {
        let location = locationManager?.location
        
        DispatchQueue.global(qos: .background).async {
            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized else { return }
                PHPhotoLibrary.shared().performChanges{
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    
                    creationRequest.addResource(with: .photo, data: imageData, options: nil)
                    if let location = location {
                        creationRequest.location = location
                    }
                } completionHandler: { success, error in
                    DispatchQueue.main.async {
                        if success {
                            self.isPhotoSaved = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                self.isPhotoSaved = false
                            }
                        }
                        if let error = error {
                            print ("Error saving photo to library: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Location Manager
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()
    }
}


