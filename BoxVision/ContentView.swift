import SwiftUI
import PhotosUI
import Vision
import CoreML
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showing_camera = false
    
    @State private var showingModelPicker = false
    @StateObject private var viewModel = ModelViewModel()
    
    @State private var showSplash = true
    @State private var showBanner = false
    @State private var bannerTitle = ""
    @State private var bannerSubtitle = ""
    
    @State private var showResultsView = false
    
    func validateAndRun() {
        if !viewModel.isModelLoaded || !viewModel.isImageLoaded {
            bannerTitle = "Something is missing!"
            bannerSubtitle = !viewModel.isModelLoaded ? "Please load a model" : "Please select an image"
            withAnimation { showBanner = true }
            return
        }
        
        if let image = selectedImage {
            viewModel.runModel(on: image)
            showResultsView = true
        }
    }

    var body: some View {
        Group {
            if showSplash {
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
                            showSplash = false
                        }
                    }
            } else {
                NavigationStack {
                    ZStack {
                        Color(white: 0.98).ignoresSafeArea() // Sfondo chiaro come mockup
                        
                        VStack(spacing: 20) {
                            // Header
                            VStack(spacing: 4) {
                                Text("Box Vision")
                                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text("Object detection")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 10)
                            
                            // Image Preview Area
                            ZStack {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color(white: 0.95))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .strokeBorder(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                                    )
                                
                                if let selectedImage = selectedImage {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 220)
                                        .clipShape(RoundedRectangle(cornerRadius: 24))
                                } else {
                                    VStack(spacing: 12) {
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .font(.system(size: 30))
                                            .foregroundColor(.blue)
                                            .padding(12)
                                            .background(Color.blue.opacity(0.1))
                                            .clipShape(Circle())
                                        
                                        Text("No image selected")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .frame(height: 220)
                            .padding(.horizontal)

                            // Model Status Badge
                            if viewModel.isModelLoaded {
                                HStack(spacing: 8) {
                                    Circle().fill(Color.green).frame(width: 8, height: 8)
                                    Text("yolov8s.mlpackage loaded") // Nome dinamico se disponibile
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.green)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(10)
                            }

                            // Interaction Buttons
                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    // Take Photo
                                    Button { showing_camera = true } label: {
                                        Label("Take photo", systemImage: "camera.fill")
                                            .font(.system(size: 15, weight: .medium))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(Color.black)
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                    }
                                    
                                    // Gallery Picker
                                    PhotosPicker(selection: $selectedItem, matching: .images) {
                                        Label("Gallery", systemImage: "photo.stack")
                                            .font(.system(size: 15, weight: .medium))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(Color.white)
                                            .foregroundColor(.primary)
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                                    }
                                }
                                
                                // Load Model Button
                                Button { showingModelPicker = true } label: {
                                    Text("Load model (.mlpackage)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.white)
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                                }
                            }
                            .padding(.horizontal)

                            Spacer()

                            // Action Footer
                            VStack(spacing: 16) {
                                Button { validateAndRun() } label: {
                                    Text("Run detection")
                                        .font(.system(size: 16, weight: .bold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(viewModel.isImageLoaded && viewModel.isModelLoaded ? Color.black : Color.gray.opacity(0.5))
                                        .foregroundColor(.white)
                                        .cornerRadius(14)
                                }
                                
                                Button {
                                    selectedImage = nil
                                    selectedItem = nil
                                    viewModel.isModelLoaded = false
                                    viewModel.isImageLoaded = false
                                } label: {
                                    Text("Clear all")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                    .navigationDestination(isPresented: $showResultsView) {
                        ResultsView(image: selectedImage, detections: viewModel.detections)
                    }
                    .sheet(isPresented: $showing_camera) {
                        CameraView(image: $selectedImage)
                    }
                    .fileImporter(
                        isPresented: $showingModelPicker,
                        allowedContentTypes: [UTType.package],
                        allowsMultipleSelection: false
                    ) { result in
                        if case .success(let urls) = result {
                            viewModel.loadModel(from: urls.first!)
                        }
                    }
                    .onChange(of: selectedItem) { _ in
                        Task {
                            if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                selectedImage = image
                                viewModel.isImageLoaded = true
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview{
    ContentView()
}
