//
//  VisionService.swift
//  BoxVision
//
//  Created by Francesco De Patre on 02/04/26.
//

import Foundation
import Vision
import CoreML

class VisionService {
    
    static func createRequest(model: VNCoreMLModel, completion: @escaping ([VNRecognizedObjectObservation]) -> Void) -> VNCoreMLRequest {
        
        let request = VNCoreMLRequest(model: model) { request, error in
            
            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                completion([])
                return
            }
            
            completion(results)
        }
        
        request.imageCropAndScaleOption = .scaleFill
        return request
    }
}
