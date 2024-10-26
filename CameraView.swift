//
//  CameraView.swift
//  SimpleFusionCam
//
//  Created by Andriyanto Halim on 26/10/24.
//

import SwiftUI
import AVFoundation

import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    
    var body: some View {
        ZStack {
            if let previewLayer = viewModel.getPreviewLayer() {
                CameraPreview(previewLayer: previewLayer)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        FocusIndicatorView(focusPoint: viewModel.touchPoint)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        let frame = UIScreen.main.bounds
                        viewModel.setFocus(to: location, in: frame)
                    }
            } else {
                Text("Loading Camera...").foregroundColor(.white)
            }
            
            GuideLinesView()
            
            VStack {
                Spacer()
                
                HStack {
                    Button(action: {
                        viewModel.UltraWideLens()
                        viewModel.lensSelectionHapticFeedback()
                    }) {
                        Text("0.5x")
                            .font(.system(size: 13))
                            .fontWeight(.medium)
                            .frame(width: 45, height: 45)
                            .clipShape(Circle())
                            .foregroundColor(Color.white)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 50, height: 50)
                            )
                    }
                    .padding()
                    
                    Button(action: {
                        viewModel.PrimeWideLens()
                        viewModel.lensSelectionHapticFeedback()
                    }) {
                        Text("1.0x")
                            .font(.system(size: 13))
                            .fontWeight(.medium)
                            .frame(width: 45, height: 45)
                            .clipShape(Circle())
                            .foregroundColor(Color.white)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 50, height: 50)
                            )
                    }
                    .padding()
                    
                    Button(action: {
                        viewModel.TelephotoLens()
                        viewModel.lensSelectionHapticFeedback()
                    }) {
                        Text("2.0x")
                            .font(.system(size: 13))
                            .fontWeight(.medium)
                            .frame(width: 45, height: 45)
                            .clipShape(Circle())
                            .foregroundColor(Color.white)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 50, height: 50)
                            )
                    }
                    .padding()
                }
                .padding(.bottom, 30)
                
                HStack {
                    LEDIndicator(isOn: viewModel.isPhotoSaved)
                        .padding(.leading, 30)
                    
                    Spacer()
                    
                    ShutterButton(action: {
                        viewModel.capturePhoto()
                    })
                    
                    Spacer()
                    
                    FrontBackLensSelectButton(action: {
                        return
                    })
                    .padding(.trailing, 30)
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            viewModel.startSession()
        }
    }
}

// MARK: - Components
struct FocusIndicatorView: View {
    var focusPoint: CGPoint?
    
    var body: some View {
        if let point = focusPoint {
            Rectangle()
                .stroke(Color.yellow, lineWidth: 1)
                .frame(width: 80, height: 80)
                .position(point)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: focusPoint)
        }
    }
}

struct GuideLinesView: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            Path { path in
                // Horizontal lines
                path.move(to: CGPoint(x: 0, y: height / 3))
                path.addLine(to: CGPoint(x: width, y: height / 3))
                
                path.move(to: CGPoint(x: 0, y: 2 * height / 3))
                path.addLine(to: CGPoint(x: width, y: 2 * height / 3))
                
                // Vertical lines
                path.move(to: CGPoint(x: width / 3, y: 0))
                path.addLine(to: CGPoint(x: width / 3, y: height))
                
                path.move(to: CGPoint(x: 2 * width / 3, y: 0))
                path.addLine(to: CGPoint(x: 2 * width / 3, y: height))
            }
            .stroke(Color.white.opacity(0.5), lineWidth: 1)
        }
        .allowsHitTesting(false) // This ensures the guide lines don't interfere with touch events
    }
}

struct LEDIndicator: View {
    var isOn: Bool
    
    var body: some View {
        Circle()
            .fill(Color.white).opacity(0)
            .frame(width: 50, height: 50)
            .overlay(
                Circle()
                    .fill(isOn ? Color.green : Color.gray)
                    .stroke(Color.white, lineWidth: 1)
                    .frame(width: 20, height: 20)
            )
            .shadow(radius: isOn ? 5 : 0)
            .animation(.default, value: isOn)
    }
}

struct FrontBackLensSelectButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            Text("")
                .font(.largeTitle)
                .frame(width: 50, height: 50)
                .opacity(0.8)
        }
    }
}

struct ShutterButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            Circle()
                .fill(Color.white)
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 90, height: 90)
                )
        }
    }
}

// A helper struct to wrap the preview layer into a SwiftUI view
struct CameraPreview: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        if let previewLayer = previewLayer {
            previewLayer.frame = UIScreen.main.bounds
            view.layer.addSublayer(previewLayer)
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Preview
#Preview {
    CameraView()
}
