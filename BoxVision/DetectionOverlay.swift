//
//  DetectionOverlay.swift
//  BoxVision
//
//  Created by Francesco De Patre on 02/04/26.
//

import Foundation
import SwiftUI
import Vision

struct DetectionOverlayView: View {
    
    let detections: [VNRecognizedObjectObservation]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(detections, id: \.self) { detection in
                    
                    let rect = detection.boundingBox
                    
                    Rectangle()
                        .stroke(Color.red, lineWidth: 2)
                        .frame(
                            width: rect.width * geo.size.width,
                            height: rect.height * geo.size.height
                        )
                        .position(
                            x: rect.midX * geo.size.width,
                            y: (1 - rect.midY) * geo.size.height
                        )
                }
            }
        }
    }
}
