//
//  LoadModel.swift
//  BoxVision
//

import Foundation
import CoreML
import Vision
import SwiftUI
import Combine

// Extension FUORI dalla classe
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

class ModelViewModel: ObservableObject {
    @Published var visionModel: VNCoreMLModel?
    @Published var modelURL: URL?
    @Published var isModelLoaded: Bool = false
    @Published var isImageLoaded: Bool = false
    @Published var detections: [Detection] = []

    let cocoClasses = [
        "person","bicycle","car","motorcycle","airplane","bus","train","truck",
        "boat","traffic light","fire hydrant","stop sign","parking meter","bench",
        "bird","cat","dog","horse","sheep","cow","elephant","bear","zebra","giraffe",
        "backpack","umbrella","handbag","tie","suitcase","frisbee","skis","snowboard",
        "sports ball","kite","baseball bat","baseball glove","skateboard","surfboard",
        "tennis racket","bottle","wine glass","cup","fork","knife","spoon","bowl",
        "banana","apple","sandwich","orange","broccoli","carrot","hot dog","pizza",
        "donut","cake","chair","couch","potted plant","bed","dining table","toilet",
        "tv","laptop","mouse","remote","keyboard","cell phone","microwave","oven",
        "toaster","sink","refrigerator","book","clock","vase","scissors",
        "teddy bear","hair drier","toothbrush"
    ]

    func loadModel(from url: URL) {
        let gotAccess = url.startAccessingSecurityScopedResource()
        defer {
            if gotAccess { url.stopAccessingSecurityScopedResource() }
        }

        do {
            let fileManager = FileManager.default
            let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destURL = docsDir.appendingPathComponent(url.lastPathComponent)

            if fileManager.fileExists(atPath: destURL.path) {
                try fileManager.removeItem(at: destURL)
            }
            try fileManager.copyItem(at: url, to: destURL)

            let compiledURL = try MLModel.compileModel(at: destURL)
            let mlModel = try MLModel(contentsOf: compiledURL)
            let vnModel = try VNCoreMLModel(for: mlModel)

            DispatchQueue.main.async {
                self.visionModel = vnModel
                self.isModelLoaded = true
            }
        } catch {
            print("Error loading model:", error)
        }
    }

    func runModel(on image: UIImage) {
        guard let visionModel = visionModel else {
            print("Modello non caricato")
            return
        }

        let request = VNCoreMLRequest(model: visionModel) { request, error in
            if let error = error {
                print("Vision error:", error)
                return
            }

            if let results = request.results as? [VNRecognizedObjectObservation], !results.isEmpty {
                DispatchQueue.main.async { self.handleDetections(results) }
                return
            }

            if let results = request.results as? [VNCoreMLFeatureValueObservation] {
                print("Output grezzo ricevuto, parsing manuale")
                DispatchQueue.main.async {
                    self.detections = self.parseRawYOLOOutput(results)
                }
                return
            }

            print("Tipo output non riconosciuto:", type(of: request.results))
        }

        request.imageCropAndScaleOption = .scaleFill

        guard let cgImage = image.cgImage else { return }
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Vision error:", error)
        }
    }

    func parseRawYOLOOutput(_ results: [VNCoreMLFeatureValueObservation]) -> [Detection] {
        guard let first = results.first,
              let multiArray = first.featureValue.multiArrayValue else { return [] }

        let numBoxes = 8400
        let numClasses = 80
        let confidenceThreshold: Float = 0.3
        var detections: [Detection] = []

        for i in 0..<numBoxes {
            let cx = multiArray[[0, 0, i] as [NSNumber]].floatValue
            let cy = multiArray[[0, 1, i] as [NSNumber]].floatValue
            let w  = multiArray[[0, 2, i] as [NSNumber]].floatValue
            let h  = multiArray[[0, 3, i] as [NSNumber]].floatValue

            var maxConf: Float = 0
            var maxClass = 0
            for c in 0..<numClasses {
                let conf = multiArray[[0, (4 + c), i] as [NSNumber]].floatValue
                if conf > maxConf {
                    maxConf = conf
                    maxClass = c
                }
            }

            guard maxConf >= confidenceThreshold else { continue }

            // YOLOv8 usa coordinate normalizzate 0..640 → dividi per 640
            // Se già 0..1 salta la divisione
            let x = CGFloat(cx / 640 - w / 1280)
            let y = CGFloat(1 - cy / 640 - h / 1280) // flip per Vision (origin bottom-left)
            let rect = CGRect(x: x, y: y, width: CGFloat(w / 640), height: CGFloat(h / 640))

            let label = cocoClasses[safe: maxClass] ?? "class_\(maxClass)"
            detections.append(Detection(label: label, confidence: maxConf, boundingBox: rect))
        }

        return applyNMS(detections)
    }

    func handleDetections(_ results: [VNRecognizedObjectObservation]) {
        self.detections = results.map { observation in
            Detection(
                label: observation.labels.first?.identifier ?? "Unknown",
                confidence: observation.labels.first?.confidence ?? 0,
                boundingBox: observation.boundingBox
            )
        }
    }
    
    func applyNMS(_ detections: [Detection], iouThreshold: Float = 0.45) -> [Detection] {
        // Raggruppa per classe
        let classes = Set(detections.map { $0.label })
        var kept: [Detection] = []

        for cls in classes {
            // Ordina per confidenza decrescente
            var candidates = detections
                .filter { $0.label == cls }
                .sorted { $0.confidence > $1.confidence }

            while !candidates.isEmpty {
                let best = candidates.removeFirst()
                kept.append(best)

                // Rimuovi tutte le box con IoU alto rispetto a best
                candidates = candidates.filter { iou(best.boundingBox, $0.boundingBox) < iouThreshold }
            }
        }

        return kept
    }

    func iou(_ a: CGRect, _ b: CGRect) -> Float {
        let intersection = a.intersection(b)
        guard !intersection.isNull else { return 0 }

        let interArea = intersection.width * intersection.height
        let unionArea = a.width * a.height + b.width * b.height - interArea

        guard unionArea > 0 else { return 0 }
        return Float(interArea / unionArea)
    }
}
